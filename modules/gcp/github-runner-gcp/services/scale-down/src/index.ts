import {
  loadConfig,
  logger,
  startServer,
  healthRoute,
  type Handler,
  listRunnerVms,
  deleteRunnerVm,
  listRunners,
  deregisterRunner,
} from "@github-runner-gcp/lib";

/**
 * Cloud Run scale-down service (Cloud Scheduler-invoked).
 *
 * Mirrors the upstream `scale-down` + `ssm-housekeeper` Lambdas:
 *   - For each repository/org we have runners registered in, list runners.
 *   - Delete VMs that are:
 *       * older than minimum_running_time_in_minutes AND idle (not busy)
 *       * ephemeral and runner status is offline (job done, runner exited)
 *       * orphaned: a VM whose runner registration is gone
 *   - Deregister runners whose VMs no longer exist (cleans up stale GitHub
 *     registrations from prior failed scale-ups).
 *
 * Idempotent: safe to run on any schedule; double-invocations are no-ops.
 */

const config = loadConfig();

const ageMinutes = (creationTimestamp: string): number => {
  if (!creationTimestamp) return Number.POSITIVE_INFINITY;
  const created = Date.parse(creationTimestamp);
  if (!Number.isFinite(created)) return Number.POSITIVE_INFINITY;
  return (Date.now() - created) / 60_000;
};

const decodeRepoLabel = (label: string | undefined): { owner: string; repo: string | null } | null => {
  if (!label) return null;
  if (label.includes("_")) {
    const idx = label.indexOf("_");
    const owner = label.slice(0, idx);
    const repo = label.slice(idx + 1);
    return { owner, repo: repo.length > 0 ? repo : null };
  }
  return { owner: label, repo: null };
};

const handler: Handler = async (_req) => {
  const vms = await listRunnerVms(config);
  logger.info({ count: vms.length }, "scale-down: live VMs");

  // Group by owner+repo so we can compare against GitHub's runner list once
  // per scope rather than once per VM.
  const scopes = new Map<string, { owner: string; repo: string | null; vms: typeof vms }>();
  for (const vm of vms) {
    const key = vm.labels["repository"] ?? "";
    const decoded = decodeRepoLabel(key);
    if (!decoded) continue;
    const scopeKey = `${decoded.owner}/${decoded.repo ?? ""}`;
    if (!scopes.has(scopeKey)) {
      scopes.set(scopeKey, { owner: decoded.owner, repo: decoded.repo, vms: [] });
    }
    scopes.get(scopeKey)!.vms.push(vm);
  }

  const summary = {
    scopes: scopes.size,
    deletedVms: 0,
    deregisteredRunners: 0,
  };

  for (const { owner, repo, vms: scopeVms } of scopes.values()) {
    const runners = await listRunners(config, { owner, repo }).catch((err) => {
      logger.warn({ err, owner, repo }, "listRunners failed; skipping scope");
      return [] as Awaited<ReturnType<typeof listRunners>>;
    });
    const runnersByName = new Map(runners.map((r) => [r.name, r]));

    for (const vm of scopeVms) {
      const runner = runnersByName.get(vm.name);
      const age = ageMinutes(vm.creationTimestamp);

      // Case 1: VM exists, runner registration gone -> orphaned VM, delete.
      if (!runner) {
        if (age >= 1) {
          await deleteRunnerVm(config, vm.zone, vm.name);
          summary.deletedVms++;
        }
        continue;
      }

      // Case 2: ephemeral runner that has finished its job (offline + non-busy).
      if (config.enableEphemeralRunners && runner.status === "offline" && !runner.busy) {
        await deleteRunnerVm(config, vm.zone, vm.name);
        await deregisterRunner(config, { owner, repo, runnerId: runner.id });
        summary.deletedVms++;
        summary.deregisteredRunners++;
        continue;
      }

      // Case 3: long-running idle runner past minimum_running_time_in_minutes.
      if (
        !runner.busy &&
        runner.status === "online" &&
        age >= config.minimumRunningTimeInMinutes
      ) {
        await deregisterRunner(config, { owner, repo, runnerId: runner.id });
        await deleteRunnerVm(config, vm.zone, vm.name);
        summary.deletedVms++;
        summary.deregisteredRunners++;
        continue;
      }
    }

    // Case 4: registrations whose VMs are already gone -> deregister.
    const liveVmNames = new Set(scopeVms.map((v) => v.name));
    for (const r of runners) {
      if (
        !r.name.startsWith(`${config.prefix}-`) ||
        liveVmNames.has(r.name)
      ) {
        continue;
      }
      if (r.status === "offline" && !r.busy) {
        await deregisterRunner(config, { owner, repo, runnerId: r.id });
        summary.deregisteredRunners++;
      }
    }
  }

  logger.info(summary, "scale-down complete");
  return { status: 200, body: summary };
};

startServer({
  "/": handler,
  "/healthz": healthRoute,
});
