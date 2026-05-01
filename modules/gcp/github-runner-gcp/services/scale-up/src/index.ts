import { randomBytes } from "node:crypto";
import {
  loadConfig,
  logger,
  startServer,
  healthRoute,
  type Handler,
  countLiveRunnerVms,
  createRunnerVm,
  createRunnerJitConfig,
  isJobStillQueued,
} from "@github-runner-gcp/lib";

/**
 * Cloud Run scale-up service.
 *
 * Pub/Sub-push subscription target. The push payload is a single base64
 * message body decoded into the JSON we publish from the webhook service.
 *
 * Mirrors the upstream `scale-up` Lambda:
 *   1. Drop messages whose action != queued.
 *   2. Re-check the job is still queued (parity with enable_job_queued_check).
 *   3. Enforce runners_maximum_count.
 *   4. Mint an installation token + JIT config.
 *   5. compute.instances.insert from the instance template, falling
 *      through machine_types and zones until one accepts the request.
 */

const config = loadConfig();

interface QueuedMessage {
  action: "queued" | "completed" | "in_progress";
  jobId: number;
  runId?: number;
  labels: string[];
  repository: string | null;
  owner: string | null;
  repo: string | null;
  installationId: number | null;
}

interface PubsubPushBody {
  message?: { data?: string; attributes?: Record<string, string>; messageId?: string };
  subscription?: string;
}

const decodePush = (raw: Buffer): { payload: QueuedMessage | null; attributes: Record<string, string>; messageId: string } => {
  let body: PubsubPushBody;
  try {
    body = JSON.parse(raw.toString("utf8"));
  } catch {
    return { payload: null, attributes: {}, messageId: "" };
  }
  const attributes = body.message?.attributes ?? {};
  const messageId = body.message?.messageId ?? "";
  const data = body.message?.data;
  if (!data) return { payload: null, attributes, messageId };
  try {
    const payload = JSON.parse(Buffer.from(data, "base64").toString("utf8")) as QueuedMessage;
    return { payload, attributes, messageId };
  } catch {
    return { payload: null, attributes, messageId };
  }
};

const generateRunnerName = (): string => {
  // GCE instance names: 1-63 chars, lower-case, [a-z]([-a-z0-9]{0,61}[a-z0-9])?
  const suffix = randomBytes(4).toString("hex");
  const ts = Math.floor(Date.now() / 1000).toString(36);
  return `${config.prefix}-${ts}-${suffix}`.slice(0, 60);
};

const handler: Handler = async (req) => {
  if (req.method !== "POST") {
    return { status: 405, body: { error: "method not allowed" } };
  }

  const { payload, messageId } = decodePush(req.rawBody);
  if (!payload) {
    return { status: 200, body: { ignored: true, reason: "could not parse push body" } };
  }

  const log = logger.child({ messageId, jobId: payload.jobId, repo: payload.repository });

  if (payload.action !== "queued") {
    return { status: 200, body: { ignored: true, reason: `action=${payload.action}` } };
  }
  if (!payload.owner) {
    log.warn("missing owner in payload");
    return { status: 200, body: { ignored: true, reason: "missing owner" } };
  }

  if (config.enableJobQueuedCheck && payload.repo) {
    const stillQueued = await isJobStillQueued(config, {
      owner: payload.owner,
      repo: payload.repo,
      jobId: payload.jobId,
    });
    if (!stillQueued) {
      log.info("job no longer queued; skipping");
      return { status: 200, body: { ignored: true, reason: "job no longer queued" } };
    }
  }

  const live = await countLiveRunnerVms(config);
  if (live >= config.runnersMaximumCount) {
    log.warn({ live, max: config.runnersMaximumCount }, "runners_maximum_count reached");
    return { status: 200, body: { ignored: true, reason: "max runners reached" } };
  }

  const runnerName = generateRunnerName();
  const runnerLabels = [
    ...(config.runnerDisableDefaultLabels ? [] : ["self-hosted", "linux", config.runnerArchitecture]),
    ...config.runnerLabels,
  ];

  let jitConfig: string;
  try {
    jitConfig = await createRunnerJitConfig(config, {
      owner: payload.owner,
      repo: payload.repo,
      runnerName,
      labels: runnerLabels,
    });
  } catch (err) {
    log.error({ err }, "failed to create JIT config");
    return { status: 500, body: { error: "jit config failed" } };
  }

  let lastErr: unknown;
  for (const machineType of config.machineTypes) {
    for (const zone of config.zones) {
      try {
        const vm = await createRunnerVm(config, {
          runnerName,
          jitConfig,
          machineType,
          zone,
          extraLabels: { repository: (payload.repository ?? "").replace("/", "_").toLowerCase().slice(0, 63) },
        });
        log.info({ vm, machineType, zone }, "scale-up succeeded");
        return { status: 200, body: { vm, machineType, zone } };
      } catch (err) {
        lastErr = err;
        log.warn({ err, machineType, zone }, "instance insert failed; trying next combination");
      }
    }
  }

  log.error({ err: lastErr }, "scale-up exhausted all machine_types x zones");
  return { status: 500, body: { error: "no capacity available" } };
};

startServer({
  "/": handler,
  "/healthz": healthRoute,
});
