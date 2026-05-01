# github-runner-gcp

Production-ready Terraform module that provisions a webhook-driven, ephemeral, self-hosted GitHub Actions runner fleet on Google Cloud, mirroring the architecture of the AWS [`github-aws-runners/github-runner/aws`](https://github.com/github-aws-runners/terraform-aws-github-runner) module that the sibling `aws_self_hosted_runner` module wraps.

```text
GitHub workflow_job webhook
        │ (HMAC-SHA256 signed)
        ▼
[Cloud Run: webhook]  ──► [Pub/Sub topic: build-jobs] ──► [Pub/Sub push (OIDC)] ──► [Cloud Run: scale-up] ──► compute.instances.insert (Spot)
                                       │ DLQ on 5 failed deliveries                                          │
                                       ▼                                                                     ▼
                            [Pub/Sub topic: build-jobs-dlq]                                       Ephemeral GCE runner VM
                                                                                                              │
[Cloud Scheduler] ─► [Cloud Run: scale-down]   ─► deregister + delete idle/orphaned VMs                       │ run.sh --jitconfig
[Cloud Scheduler] ─► [Cloud Run: runner-binaries-syncer] ─► GCS bucket                                        ▼
                                                                                              [GitHub Actions runner registers with org/repo]
```

## What this module creates

| Component | Resources |
| --- | --- |
| Webhook receiver | `google_cloud_run_v2_service.webhook` (allUsers, signature-verified inside the container) |
| Build job queue | `google_pubsub_topic.build_jobs` + `google_pubsub_topic.build_jobs_dlq` + `google_pubsub_subscription.build_jobs` (push, OIDC, dead_letter_policy with 5 attempts) |
| Scale-up | `google_cloud_run_v2_service.scale_up` (internal-only, Pub/Sub-push subscriber) |
| Scale-down | `google_cloud_run_v2_service.scale_down` + `google_cloud_scheduler_job.scale_down` |
| Runner binary cache | `google_cloud_run_v2_service.runner_binaries_syncer` + `google_cloud_scheduler_job.runner_binaries_syncer` + `google_storage_bucket.runner_binaries` |
| Runner fleet | `google_compute_instance_template.runner` + per-job `google_compute_instance` (created by scale-up via the API) |
| Identity | 6 service accounts (one per Cloud Run service, one runner SA, one OIDC-invoker SA) + scoped IAM bindings |
| Networking | egress-only firewall rules on the runner network tag (runner VMs are public, no Cloud NAT) |
| Secrets | three caller-managed Secret Manager secrets, surfaced into the services via env vars; module only grants accessor IAM |
| Observability | three log-based metrics (`<prefix>/webhook_received`, `/scale_up_failures`, `/runner_vm_created`) when `enable_audit_metrics = true` |

## Prerequisites

You must create the following **before** invoking this module (all in `var.project_id`):

1. **GitHub App** ([docs](https://docs.github.com/en/apps/creating-github-apps)) with these repository/organization permissions:
   - `Actions: Read & Write` (manage runners + read jobs)
   - `Administration: Read & Write` (register runners on org/repo)
   - `Metadata: Read`
   - Subscribe to `Workflow jobs` events.
2. **Three Secret Manager secrets** in the same project. Pass their full resource IDs (`projects/<p>/secrets/<n>`) to the module:
   - `github_app_id_secret_id` — plaintext numeric App ID.
   - `github_app_private_key_secret_id` — App private key, PEM (raw or base64).
   - `github_webhook_secret_secret_id` — webhook secret used to sign deliveries.
3. **VPC + subnetwork** in `var.region`. Pass their self-links to `var.network` and `var.subnetwork`. The module does not manage VPC/subnet lifecycle (separation of concerns). Runner VMs receive an ephemeral external IP automatically — no Cloud NAT required.
4. **APIs enabled**: `run.googleapis.com`, `pubsub.googleapis.com`, `compute.googleapis.com`, `cloudscheduler.googleapis.com`, `secretmanager.googleapis.com`, `artifactregistry.googleapis.com`, `cloudbuild.googleapis.com`, `storage.googleapis.com`, `logging.googleapis.com`.

## Building the control-plane images

The module ships TypeScript source for the four Cloud Run services under [`services/`](services). The default image references in `main.tf > locals.control_plane_images` use placeholder digests that the `image_pins_present` check rejects. Build and pin real digests with:

```sh
cd modules/gcp/github-runner-gcp/services
make cloudbuild REPO=<region>-docker.pkg.dev/<project>/<artifact-registry-repo> MODULE_VER=0.1.0
make digests   REPO=<region>-docker.pkg.dev/<project>/<artifact-registry-repo> MODULE_VER=0.1.0
```

Paste the rendered map into `locals.control_plane_images` and commit. Alternatively, supply the four `*_image` inputs at the call site (`webhook_image`, `scale_up_image`, `scale_down_image`, `runner_binaries_syncer_image`) — useful for per-environment image promotion.

## Caller IAM

The principal running `terraform apply` (or the Terragrunt service account) needs the following project-level roles in `var.project_id`:

- `roles/run.admin`
- `roles/iam.serviceAccountAdmin` and `roles/iam.serviceAccountUser`
- `roles/pubsub.admin`
- `roles/cloudscheduler.admin`
- `roles/storage.admin` (to manage the runner-binaries bucket)
- `roles/compute.networkAdmin` (firewall rules)
- `roles/compute.instanceAdmin.v1` (instance templates)
- `roles/secretmanager.admin` (to grant secretAccessor on the three secrets)
- `roles/cloudkms.admin` if `var.kms_key_self_link` is supplied

## After apply

1. `terraform output webhook_endpoint` -> POST URL.
2. In the GitHub App settings, set the webhook URL to that value, content type `application/json`, secret = the same value as `github_webhook_secret_secret_id`, and subscribe to `Workflow jobs`.
3. Trigger the runner-binaries-syncer once manually (`gcloud scheduler jobs run <prefix>-runner-binaries-syncer --location=<region>`) so the GCS bucket has a runner tarball before the first job lands.
4. Push a workflow with `runs-on: [self-hosted, iac]` (or whatever you put in `runner_extra_labels`).

## Parity table with the AWS module

| AWS variable | GCP variable | Notes |
| --- | --- | --- |
| `aws_region` | `region` (+ `zones`) | GCP needs zones for ephemeral VMs |
| `vpc_id` | `network` | self-link |
| `subnet_ids` | `subnetwork` | single subnetwork; multi-zone redundancy is via `zones` |
| `github_app_private_key_secret_arn` | `github_app_private_key_secret_id` | Secret Manager resource ID |
| `github_app_id_ssm_parameter_name` | `github_app_id_secret_id` | |
| `github_webhook_secret_arn` | `github_webhook_secret_secret_id` | |
| `github_app_installation_id_ssm_parameter_name` | `github_app_installation_id_secret_id` | optional, parity output |
| `instance_types` | `machine_types` | |
| `instance_target_capacity_type` | `instance_target_capacity_type` | `spot` -> Spot VMs |
| `runner_architecture` | `runner_architecture` | `x64` / `arm64` |
| `block_device_mappings` | `disk` (object) | single boot disk on GCP |
| `runners_maximum_count` | `runners_maximum_count` | enforced by counting live VMs by label |
| `minimum_running_time_in_minutes` | `minimum_running_time_in_minutes` | |
| `enable_ephemeral_runners` | `enable_ephemeral_runners` | |
| `enable_job_queued_check` | `enable_job_queued_check` | |
| `enable_runner_workflow_job_labels_check_all` | `enable_runner_workflow_job_labels_check_all` | |
| `runner_disable_default_labels` | `runner_disable_default_labels` | |
| `runner_extra_labels` | `runner_extra_labels` | |
| `repository_white_list` | `repository_white_list` | |
| `scale_down_schedule_expression` | `scale_down_schedule_expression` | unix-cron syntax |
| `prefix` | `prefix` | |
| `tags` | `labels` | GCP doesn't have tags, uses labels |
| `logging_retention_in_days` | `logging_retention_in_days` | |
| `create_service_linked_role_spot` | _not needed_ | Spot VMs don't need a service-linked role on GCP |
| `scale_up_reserved_concurrent_executions` | `scale_up_max_instances` / `scale_up_concurrency` | Cloud Run scaling controls |

## Out of scope

- Windows runners (the AWS upstream supports them; not implemented here).
- Multi-region active/active control plane (single-region is sufficient for the AWS-parity scope).
- Cloud Monitoring alert policies (the module exports log-based metrics; downstream alerting belongs in the consumer).
- The VPC and subnetwork.
- Renovate-driven auto-bump of control-plane image digests (separate follow-up).
