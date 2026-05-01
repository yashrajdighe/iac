import { createAppAuth } from "@octokit/auth-app";
import { Octokit } from "@octokit/rest";
import type { Config } from "./config.js";
import { readSecret } from "./secrets.js";
import { logger } from "./logger.js";

/**
 * Helpers around @octokit. The App's installation token is short-lived
 * (~1 hour) so we re-mint per request rather than maintain a cache.
 */

let cachedApp: Octokit | undefined;

const appOctokit = async (config: Config): Promise<Octokit> => {
  if (cachedApp) return cachedApp;

  const [appId, privateKey] = await Promise.all([
    readSecret(config.githubAppIdSecret),
    readSecret(config.githubAppPrivateKeySecret),
  ]);

  cachedApp = new Octokit({
    authStrategy: createAppAuth,
    auth: {
      appId: appId.trim(),
      privateKey: privateKey.includes("BEGIN")
        ? privateKey
        : Buffer.from(privateKey, "base64").toString("utf8"),
    },
  });
  return cachedApp;
};

export const installationOctokit = async (
  config: Config,
  owner: string,
  repo: string | null,
): Promise<Octokit> => {
  const app = await appOctokit(config);
  let installationId: number;

  if (config.githubAppInstallationIdSecret) {
    const stored = await readSecret(config.githubAppInstallationIdSecret);
    installationId = Number.parseInt(stored.trim(), 10);
    if (!Number.isFinite(installationId)) {
      throw new Error(
        `GITHUB_APP_INSTALLATION_ID_SECRET payload is not a number: ${stored}`,
      );
    }
  } else if (repo) {
    const { data } = await app.rest.apps.getRepoInstallation({ owner, repo });
    installationId = data.id;
  } else {
    const { data } = await app.rest.apps.getOrgInstallation({ org: owner });
    installationId = data.id;
  }

  const [appId, privateKey] = await Promise.all([
    readSecret(config.githubAppIdSecret),
    readSecret(config.githubAppPrivateKeySecret),
  ]);

  return new Octokit({
    authStrategy: createAppAuth,
    auth: {
      appId: appId.trim(),
      privateKey: privateKey.includes("BEGIN")
        ? privateKey
        : Buffer.from(privateKey, "base64").toString("utf8"),
      installationId,
    },
  });
};

export interface JitConfigParams {
  owner: string;
  repo: string | null;
  runnerName: string;
  labels: string[];
  workFolder?: string;
}

export const createRunnerJitConfig = async (
  config: Config,
  params: JitConfigParams,
): Promise<string> => {
  const octokit = await installationOctokit(config, params.owner, params.repo);

  const labels = params.labels;
  const workFolder = params.workFolder ?? "_work";

  if (params.repo) {
    const { data } = await octokit.request(
      "POST /repos/{owner}/{repo}/actions/runners/generate-jitconfig",
      {
        owner: params.owner,
        repo: params.repo,
        name: params.runnerName,
        runner_group_id: 1,
        labels,
        work_folder: workFolder,
      },
    );
    return (data as { encoded_jit_config: string }).encoded_jit_config;
  }

  const { data } = await octokit.request(
    "POST /orgs/{org}/actions/runners/generate-jitconfig",
    {
      org: params.owner,
      name: params.runnerName,
      runner_group_id: 1,
      labels,
      work_folder: workFolder,
    },
  );
  return (data as { encoded_jit_config: string }).encoded_jit_config;
};

export interface CheckJobStillQueuedParams {
  owner: string;
  repo: string;
  jobId: number;
}

export const isJobStillQueued = async (
  config: Config,
  params: CheckJobStillQueuedParams,
): Promise<boolean> => {
  try {
    const octokit = await installationOctokit(config, params.owner, params.repo);
    const { data } = await octokit.rest.actions.getJobForWorkflowRun({
      owner: params.owner,
      repo: params.repo,
      job_id: params.jobId,
    });
    return data.status === "queued";
  } catch (err) {
    logger.warn({ err, ...params }, "isJobStillQueued lookup failed");
    return false;
  }
};

export interface DeregisterRunnerParams {
  owner: string;
  repo: string | null;
  runnerId: number;
}

export const deregisterRunner = async (
  config: Config,
  params: DeregisterRunnerParams,
): Promise<void> => {
  const octokit = await installationOctokit(config, params.owner, params.repo);
  if (params.repo) {
    await octokit.rest.actions
      .deleteSelfHostedRunnerFromRepo({
        owner: params.owner,
        repo: params.repo,
        runner_id: params.runnerId,
      })
      .catch((err) => {
        logger.warn({ err, ...params }, "deleteSelfHostedRunnerFromRepo failed");
      });
  } else {
    await octokit.rest.actions
      .deleteSelfHostedRunnerFromOrg({
        org: params.owner,
        runner_id: params.runnerId,
      })
      .catch((err) => {
        logger.warn({ err, ...params }, "deleteSelfHostedRunnerFromOrg failed");
      });
  }
};

export interface ListRunnersParams {
  owner: string;
  repo: string | null;
}

export const listRunners = async (
  config: Config,
  params: ListRunnersParams,
): Promise<Array<{ id: number; name: string; status: string; busy: boolean }>> => {
  const octokit = await installationOctokit(config, params.owner, params.repo);
  if (params.repo) {
    const items = await octokit.paginate(
      octokit.rest.actions.listSelfHostedRunnersForRepo,
      { owner: params.owner, repo: params.repo, per_page: 100 },
    );
    return items.map((r) => ({ id: r.id, name: r.name, status: r.status, busy: r.busy }));
  }
  const items = await octokit.paginate(
    octokit.rest.actions.listSelfHostedRunnersForOrg,
    { org: params.owner, per_page: 100 },
  );
  return items.map((r) => ({ id: r.id, name: r.name, status: r.status, busy: r.busy }));
};
