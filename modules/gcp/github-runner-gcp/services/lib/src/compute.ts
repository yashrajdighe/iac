import { InstancesClient } from "@google-cloud/compute";
import type { Config } from "./config.js";
import { logger } from "./logger.js";

const client = new InstancesClient();

export interface RunnerVm {
  id: string;
  name: string;
  zone: string;
  selfLink: string;
  creationTimestamp: string;
  status: string;
  labels: Record<string, string>;
}

const RUNNER_LABEL_KEY = "role";
const RUNNER_LABEL_VALUE = "github-runner";

export const listRunnerVms = async (config: Config): Promise<RunnerVm[]> => {
  const filter = `labels.${RUNNER_LABEL_KEY}=${RUNNER_LABEL_VALUE} AND labels.prefix=${config.prefix}`;
  const iterable = client.aggregatedListAsync({
    project: config.projectId,
    filter,
    returnPartialSuccess: true,
  });

  const out: RunnerVm[] = [];
  for await (const [zoneKey, scopedList] of iterable) {
    const zone = zoneKey.replace(/^zones\//, "");
    const items = scopedList.instances ?? [];
    for (const inst of items) {
      if (!inst.name || !inst.selfLink) continue;
      out.push({
        id: String(inst.id ?? inst.name),
        name: inst.name,
        zone,
        selfLink: inst.selfLink,
        creationTimestamp: inst.creationTimestamp ?? "",
        status: inst.status ?? "UNKNOWN",
        labels: inst.labels ?? {},
      });
    }
  }
  return out;
};

export interface CreateRunnerVmParams {
  runnerName: string;
  jitConfig: string;
  machineType: string;
  zone: string;
  extraLabels?: Record<string, string>;
  metadata?: Record<string, string>;
}

export const createRunnerVm = async (
  config: Config,
  params: CreateRunnerVmParams,
): Promise<{ name: string; zone: string; selfLink: string }> => {
  const sanitisedLabels: Record<string, string> = {
    [RUNNER_LABEL_KEY]: RUNNER_LABEL_VALUE,
    prefix: config.prefix,
    ...(params.extraLabels ?? {}),
  };

  const metadataItems = [
    { key: "runner_jit_config", value: params.jitConfig },
    { key: "runner_idle_self_destruct_minutes", value: String(config.runnerIdleSelfDestructMinutes) },
    ...Object.entries(params.metadata ?? {}).map(([key, value]) => ({ key, value })),
  ];

  const sourceInstanceTemplate = config.instanceTemplateSelfLink;
  const machineTypeUrl = `zones/${params.zone}/machineTypes/${params.machineType}`;

  logger.info(
    { name: params.runnerName, zone: params.zone, machineType: params.machineType },
    "creating runner VM",
  );

  await client.insert({
    project: config.projectId,
    zone: params.zone,
    sourceInstanceTemplate,
    instanceResource: {
      name: params.runnerName,
      machineType: machineTypeUrl,
      labels: sanitisedLabels,
      metadata: { items: metadataItems },
    },
  });

  return {
    name: params.runnerName,
    zone: params.zone,
    selfLink: `https://www.googleapis.com/compute/v1/projects/${config.projectId}/zones/${params.zone}/instances/${params.runnerName}`,
  };
};

export const deleteRunnerVm = async (
  config: Config,
  zone: string,
  name: string,
): Promise<void> => {
  logger.info({ name, zone }, "deleting runner VM");
  await client
    .delete({
      project: config.projectId,
      zone,
      instance: name,
    })
    .catch((err: { code?: number }) => {
      if (err.code === 404) {
        logger.info({ name, zone }, "runner VM already gone");
        return;
      }
      throw err;
    });
};

export const countLiveRunnerVms = async (config: Config): Promise<number> => {
  const vms = await listRunnerVms(config);
  return vms.filter((vm) => ["PROVISIONING", "STAGING", "RUNNING", "REPAIRING"].includes(vm.status))
    .length;
};
