###############################################################################
# Locals: derived names, image digests, and label maps.
#
# Image digests vendored here mirror the lambda-zip vendoring pattern in the
# AWS wrapper (modules/aws/aws_self_hosted_runner/main.tf). Bump `module_version`
# and the four digests together when republishing the control-plane images.
###############################################################################

locals {
  module_version = "0.1.0"

  # Default control-plane images. The repo's CI builds these from
  # ./services/<name> and pushes by tag; the digest pin below freezes the
  # image identity so `terraform apply` never silently drifts.
  #
  # Replace these placeholder digests with real ones after the first CI build.
  default_image_repo = "ghcr.io/${var.project_id}/${var.prefix}"
  control_plane_images = {
    webhook                = "${local.default_image_repo}/webhook@sha256:0000000000000000000000000000000000000000000000000000000000000000"
    scale_up               = "${local.default_image_repo}/scale-up@sha256:0000000000000000000000000000000000000000000000000000000000000000"
    scale_down             = "${local.default_image_repo}/scale-down@sha256:0000000000000000000000000000000000000000000000000000000000000000"
    runner_binaries_syncer = "${local.default_image_repo}/runner-binaries-syncer@sha256:0000000000000000000000000000000000000000000000000000000000000000"
  }

  resolved_images = {
    webhook                = coalesce(var.webhook_image, local.control_plane_images.webhook)
    scale_up               = coalesce(var.scale_up_image, local.control_plane_images.scale_up)
    scale_down             = coalesce(var.scale_down_image, local.control_plane_images.scale_down)
    runner_binaries_syncer = coalesce(var.runner_binaries_syncer_image, local.control_plane_images.runner_binaries_syncer)
  }

  # Common label set merged into every label-supporting resource.
  default_labels = {
    managed_by    = "terraform"
    module        = "github-runner-gcp"
    moduleversion = replace(local.module_version, ".", "_")
    prefix        = var.prefix
  }
  labels = merge(local.default_labels, var.labels)

  # Selector for runner VMs (lookups by scale-down + runners_maximum_count
  # guard in scale-up). Kept as a separate map so it can be applied to both
  # the instance template and the network tags / firewall.
  runner_labels = merge(local.labels, {
    role   = "github-runner"
    prefix = var.prefix
  })
  runner_network_tag = "${var.prefix}-runner"

  # Resource names. GCP service accounts are <=30 chars and must match
  # ^[a-z]([-a-z0-9]*[a-z0-9])$ with a 6-char minimum, so we use short suffixes.
  sa_ids = {
    webhook    = "${var.prefix}-wh"
    scale_up   = "${var.prefix}-sup"
    scale_down = "${var.prefix}-sdn"
    binaries   = "${var.prefix}-bin"
    runner     = "${var.prefix}-rnr"
    invoker    = "${var.prefix}-inv"
  }

  service_names = {
    webhook    = "${var.prefix}-webhook"
    scale_up   = "${var.prefix}-scale-up"
    scale_down = "${var.prefix}-scale-down"
    binaries   = "${var.prefix}-runner-binaries-syncer"
  }

  topic_name        = "${var.prefix}-build-jobs"
  dlq_topic_name    = "${var.prefix}-build-jobs-dlq"
  subscription_name = "${var.prefix}-build-jobs-sub"

  binaries_bucket_name = "${var.project_id}-${var.prefix}-runner-binaries"

  instance_template_name_prefix = "${var.prefix}-runner-"

  default_image_family = var.runner_image_family != null ? var.runner_image_family : (
    var.runner_architecture == "arm64" ? "ubuntu-2404-lts-arm64" : "ubuntu-2404-lts-amd64"
  )

  runner_image = "projects/${var.runner_image_project}/global/images/family/${local.default_image_family}"

  # Pre-computed values that the runner instance template + the Cloud Run
  # services share. Defined separately from `service_env` so that
  # `runner_startup_script` (used in the instance template) can read them
  # without depending on the instance template itself, breaking the cycle.
  runner_binaries_latest_object = "latest/${var.runner_architecture}.json"

  # Shared environment block consumed by every Cloud Run service. Keeps the
  # secret-resolution and feature-flag logic in one place so the four
  # services see a consistent view of the module configuration.
  service_env = {
    GCP_PROJECT_ID                              = var.project_id
    GCP_REGION                                  = var.region
    GCP_ZONES                                   = join(",", var.zones)
    PREFIX                                      = var.prefix
    RUNNER_NETWORK_TAG                          = local.runner_network_tag
    INSTANCE_TEMPLATE_SELF_LINK                 = google_compute_instance_template.runner.self_link
    BUILD_JOB_TOPIC                             = google_pubsub_topic.build_jobs.id
    RUNNER_BINARIES_BUCKET                      = google_storage_bucket.runner_binaries.name
    RUNNER_BINARIES_LATEST_OBJECT               = local.runner_binaries_latest_object
    RUNNER_ARCHITECTURE                         = var.runner_architecture
    RUNNER_LABELS                               = join(",", var.runner_extra_labels)
    RUNNER_DISABLE_DEFAULT_LABELS               = tostring(var.runner_disable_default_labels)
    ENABLE_EPHEMERAL_RUNNERS                    = tostring(var.enable_ephemeral_runners)
    ENABLE_JOB_QUEUED_CHECK                     = tostring(var.enable_job_queued_check)
    ENABLE_RUNNER_WORKFLOW_JOB_LABELS_CHECK_ALL = tostring(var.enable_runner_workflow_job_labels_check_all)
    REPOSITORY_WHITE_LIST                       = join(",", var.repository_white_list)
    RUNNERS_MAXIMUM_COUNT                       = tostring(var.runners_maximum_count)
    MINIMUM_RUNNING_TIME_IN_MINUTES             = tostring(var.minimum_running_time_in_minutes)
    GITHUB_APP_ID_SECRET                        = var.github_app_id_secret_id
    GITHUB_APP_PRIVATE_KEY_SECRET               = var.github_app_private_key_secret_id
    GITHUB_WEBHOOK_SECRET_SECRET                = var.github_webhook_secret_secret_id
    GITHUB_APP_INSTALLATION_ID_SECRET           = coalesce(var.github_app_installation_id_secret_id, "")
    RUNNER_LABEL_PREFIX                         = var.prefix
    RUNNER_IDLE_SELF_DESTRUCT_MINUTES           = tostring(var.runner_idle_self_destruct_minutes)
    INSTANCE_TARGET_CAPACITY_TYPE               = var.instance_target_capacity_type
    MACHINE_TYPES                               = join(",", var.machine_types)
  }
}

###############################################################################
# Surface optional installation-id secret for the parity output.
###############################################################################

data "google_secret_manager_secret_version" "installation_id" {
  count   = var.github_app_installation_id_secret_id != null ? 1 : 0
  project = var.project_id
  secret  = var.github_app_installation_id_secret_id
}
