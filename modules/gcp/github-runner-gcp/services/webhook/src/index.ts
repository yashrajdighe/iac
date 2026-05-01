import { PubSub } from "@google-cloud/pubsub";
import { verify } from "@octokit/webhooks-methods";
import {
  loadConfig,
  logger,
  readSecret,
  startServer,
  healthRoute,
  type Handler,
} from "@github-runner-gcp/lib";

/**
 * Cloud Run webhook receiver.
 *
 * Mirrors the upstream `webhook` Lambda: signature-verify with the App's
 * webhook secret, filter to workflow_job events, optionally enforce
 * exact-match label semantics + repository allow-list, then publish to
 * Pub/Sub. Returns 200 fast so GitHub doesn't time out and retry.
 */

const config = loadConfig();
const pubsub = new PubSub({ projectId: config.projectId });
const topic = pubsub.topic(config.buildJobTopic.replace(/^projects\/[^/]+\/topics\//, ""));

const REQUIRED_LABEL = "self-hosted";

const matchesAllRunnerLabels = (jobLabels: string[]): boolean => {
  const runnerLabelSet = new Set([
    ...(config.runnerDisableDefaultLabels
      ? []
      : ["self-hosted", "linux", config.runnerArchitecture]),
    ...config.runnerLabels.map((l) => l.toLowerCase()),
  ]);
  return jobLabels.every((l) => runnerLabelSet.has(l.toLowerCase()));
};

const matchesAnyRunnerLabel = (jobLabels: string[]): boolean => {
  const runnerLabelSet = new Set(config.runnerLabels.map((l) => l.toLowerCase()));
  return jobLabels.some((l) => runnerLabelSet.has(l.toLowerCase()));
};

const handler: Handler = async (req) => {
  if (req.method !== "POST") {
    return { status: 405, body: { error: "method not allowed" } };
  }

  const userAgent = req.headers["user-agent"];
  if (typeof userAgent !== "string" || !userAgent.startsWith("GitHub-Hookshot/")) {
    logger.warn({ userAgent }, "rejecting non-GitHub user-agent");
    return { status: 401, body: { error: "invalid user-agent" } };
  }

  const event = req.headers["x-github-event"];
  if (event !== "workflow_job") {
    return { status: 202, body: { ignored: true, reason: "non-workflow_job event" } };
  }

  const signature = req.headers["x-hub-signature-256"];
  if (typeof signature !== "string") {
    return { status: 401, body: { error: "missing signature" } };
  }

  const secret = await readSecret(config.githubWebhookSecretSecret);
  const ok = await verify(secret, req.rawBody.toString("utf8"), signature);
  if (!ok) {
    logger.warn("signature verification failed");
    return { status: 401, body: { error: "bad signature" } };
  }

  let payload: {
    action?: string;
    workflow_job?: {
      id?: number;
      run_id?: number;
      labels?: string[];
      runner_name?: string | null;
    };
    repository?: { full_name?: string; owner?: { login?: string }; name?: string };
    organization?: { login?: string };
    installation?: { id?: number };
  };
  try {
    payload = JSON.parse(req.rawBody.toString("utf8"));
  } catch {
    return { status: 400, body: { error: "invalid json" } };
  }

  const action = payload.action;
  if (action !== "queued" && action !== "completed" && action !== "in_progress") {
    return { status: 202, body: { ignored: true, reason: `action=${action}` } };
  }

  const repoFullName = payload.repository?.full_name;
  if (
    config.repositoryWhiteList.length > 0 &&
    repoFullName &&
    !config.repositoryWhiteList.includes(repoFullName)
  ) {
    return { status: 202, body: { ignored: true, reason: "repo not allow-listed" } };
  }

  const jobLabels = (payload.workflow_job?.labels ?? []).map((l) => l.toLowerCase());
  if (!jobLabels.includes(REQUIRED_LABEL)) {
    return { status: 202, body: { ignored: true, reason: "missing self-hosted label" } };
  }

  const labelMatch = config.enableRunnerWorkflowJobLabelsCheckAll
    ? matchesAllRunnerLabels(jobLabels)
    : matchesAnyRunnerLabel(jobLabels);
  if (!labelMatch) {
    return { status: 202, body: { ignored: true, reason: "labels do not match runner pool" } };
  }

  const message = {
    action,
    jobId: payload.workflow_job?.id,
    runId: payload.workflow_job?.run_id,
    runnerName: payload.workflow_job?.runner_name,
    labels: jobLabels,
    repository: repoFullName ?? null,
    owner: payload.repository?.owner?.login ?? payload.organization?.login ?? null,
    repo: payload.repository?.name ?? null,
    installationId: payload.installation?.id ?? null,
    receivedAt: new Date().toISOString(),
  };

  const messageId = await topic.publishMessage({
    json: message,
    attributes: {
      action: action,
      "github-event": "workflow_job",
    },
  });
  logger.info({ messageId, action, jobId: message.jobId }, "published to build-jobs");

  return { status: 200, body: { messageId, action } };
};

startServer({
  "/": handler,
  "/webhook": handler,
  "/healthz": healthRoute,
});
