/**
 * Read-only configuration shared by every Cloud Run service.
 *
 * The values originate in `locals.service_env` in the module's main.tf so
 * that all four services have a single source of truth for feature flags
 * and resource references. Throwing here on missing required vars makes
 * misconfiguration fail fast at container start instead of at request time.
 */

const required = (name: string): string => {
  const value = process.env[name];
  if (value === undefined || value === "") {
    throw new Error(`Required env var ${name} is missing or empty`);
  }
  return value;
};

const optional = (name: string, fallback = ""): string =>
  process.env[name] ?? fallback;

const boolFlag = (name: string, fallback: boolean): boolean => {
  const v = process.env[name];
  if (v === undefined) return fallback;
  return v === "true" || v === "1";
};

const intVal = (name: string, fallback: number): number => {
  const v = process.env[name];
  if (v === undefined || v === "") return fallback;
  const n = Number.parseInt(v, 10);
  return Number.isFinite(n) ? n : fallback;
};

const list = (name: string): string[] => {
  const v = process.env[name];
  if (!v) return [];
  return v.split(",").map((s) => s.trim()).filter(Boolean);
};

export interface Config {
  projectId: string;
  region: string;
  zones: string[];
  prefix: string;
  runnerNetworkTag: string;
  instanceTemplateSelfLink: string;
  buildJobTopic: string;
  runnerBinariesBucket: string;
  runnerBinariesLatestObject: string;
  runnerArchitecture: "x64" | "arm64";
  runnerLabels: string[];
  runnerDisableDefaultLabels: boolean;
  enableEphemeralRunners: boolean;
  enableJobQueuedCheck: boolean;
  enableRunnerWorkflowJobLabelsCheckAll: boolean;
  repositoryWhiteList: string[];
  runnersMaximumCount: number;
  minimumRunningTimeInMinutes: number;
  githubAppIdSecret: string;
  githubAppPrivateKeySecret: string;
  githubWebhookSecretSecret: string;
  githubAppInstallationIdSecret: string;
  runnerLabelPrefix: string;
  runnerIdleSelfDestructMinutes: number;
  instanceTargetCapacityType: "spot" | "on-demand";
  machineTypes: string[];
}

let cached: Config | undefined;

export const loadConfig = (): Config => {
  if (cached) return cached;

  const arch = required("RUNNER_ARCHITECTURE");
  if (arch !== "x64" && arch !== "arm64") {
    throw new Error(`Unsupported RUNNER_ARCHITECTURE: ${arch}`);
  }

  const capacity = required("INSTANCE_TARGET_CAPACITY_TYPE");
  if (capacity !== "spot" && capacity !== "on-demand") {
    throw new Error(`Unsupported INSTANCE_TARGET_CAPACITY_TYPE: ${capacity}`);
  }

  cached = {
    projectId: required("GCP_PROJECT_ID"),
    region: required("GCP_REGION"),
    zones: list("GCP_ZONES"),
    prefix: required("PREFIX"),
    runnerNetworkTag: required("RUNNER_NETWORK_TAG"),
    instanceTemplateSelfLink: required("INSTANCE_TEMPLATE_SELF_LINK"),
    buildJobTopic: required("BUILD_JOB_TOPIC"),
    runnerBinariesBucket: required("RUNNER_BINARIES_BUCKET"),
    runnerBinariesLatestObject: required("RUNNER_BINARIES_LATEST_OBJECT"),
    runnerArchitecture: arch,
    runnerLabels: list("RUNNER_LABELS"),
    runnerDisableDefaultLabels: boolFlag("RUNNER_DISABLE_DEFAULT_LABELS", true),
    enableEphemeralRunners: boolFlag("ENABLE_EPHEMERAL_RUNNERS", true),
    enableJobQueuedCheck: boolFlag("ENABLE_JOB_QUEUED_CHECK", true),
    enableRunnerWorkflowJobLabelsCheckAll: boolFlag(
      "ENABLE_RUNNER_WORKFLOW_JOB_LABELS_CHECK_ALL",
      true,
    ),
    repositoryWhiteList: list("REPOSITORY_WHITE_LIST"),
    runnersMaximumCount: intVal("RUNNERS_MAXIMUM_COUNT", 1),
    minimumRunningTimeInMinutes: intVal("MINIMUM_RUNNING_TIME_IN_MINUTES", 3),
    githubAppIdSecret: required("GITHUB_APP_ID_SECRET"),
    githubAppPrivateKeySecret: required("GITHUB_APP_PRIVATE_KEY_SECRET"),
    githubWebhookSecretSecret: required("GITHUB_WEBHOOK_SECRET_SECRET"),
    githubAppInstallationIdSecret: optional("GITHUB_APP_INSTALLATION_ID_SECRET"),
    runnerLabelPrefix: required("RUNNER_LABEL_PREFIX"),
    runnerIdleSelfDestructMinutes: intVal("RUNNER_IDLE_SELF_DESTRUCT_MINUTES", 30),
    instanceTargetCapacityType: capacity,
    machineTypes: list("MACHINE_TYPES"),
  };
  return cached;
};
