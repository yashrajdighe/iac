###############################################################################
# Identity & networking
###############################################################################

variable "project_id" {
  description = "GCP project where every resource of the runner control plane and runner fleet is created."
  type        = string
}

variable "region" {
  description = "Region for Cloud Run, Pub/Sub, Cloud Scheduler, GCS bucket and the regional managed resources."
  type        = string
}

variable "zones" {
  description = "Zones (in `region`) eligible for ephemeral runner VMs. Scale-up picks the first zone with capacity; falls back through the list."
  type        = list(string)

  validation {
    condition     = length(var.zones) >= 1
    error_message = "At least one zone must be supplied."
  }
}

variable "network" {
  description = "Self link or `projects/<p>/global/networks/<name>` of the VPC the runner VMs join."
  type        = string
}

variable "subnetwork" {
  description = "Self link or `projects/<p>/regions/<r>/subnetworks/<name>` for the runner VMs (must be in `region`)."
  type        = string
}

variable "prefix" {
  description = "Resource name prefix. Used for SAs, Cloud Run services, Pub/Sub topics, GCS bucket suffix, instance template name. Must be 4-30 chars to fit GCE name limits with random suffixes."
  type        = string
  default     = "github-actions"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{2,28}[a-z0-9])$", var.prefix))
    error_message = "prefix must match ^[a-z]([-a-z0-9]{2,28}[a-z0-9])$ (lower-case, 4-30 chars)."
  }
}

variable "labels" {
  description = "Labels merged into every label-supporting resource (Cloud Run, GCS, Pub/Sub, instance template, etc.). Replaces the AWS module's `tags` input."
  type        = map(string)
  default     = {}
}

###############################################################################
# GitHub App authentication (Secret Manager resource IDs in `project_id`)
###############################################################################

variable "github_app_id_secret_id" {
  description = "Resource ID of the Secret Manager secret holding the numeric GitHub App ID (plain string). Format `projects/<p>/secrets/<name>`."
  type        = string
}

variable "github_app_private_key_secret_id" {
  description = "Resource ID of the Secret Manager secret holding the GitHub App private key as a PEM (raw, not base64)."
  type        = string
}

variable "github_webhook_secret_secret_id" {
  description = "Resource ID of the Secret Manager secret holding the GitHub App webhook secret used to verify X-Hub-Signature-256."
  type        = string
}

variable "github_app_installation_id_secret_id" {
  description = "Optional. Resource ID of a Secret Manager secret holding a numeric installation ID. Surfaced via output `github_app_installation_id_from_secret`; the App is also able to derive installations dynamically."
  type        = string
  default     = null
}

###############################################################################
# Runner fleet
###############################################################################

variable "machine_types" {
  description = "Compute Engine machine types for ephemeral runners. Scale-up uses the first one and falls through the list when capacity is exhausted (parity with AWS instance_types)."
  type        = list(string)
  default     = ["c4-standard-4"]

  validation {
    condition     = length(var.machine_types) >= 1
    error_message = "At least one machine type must be supplied."
  }
}

variable "runner_architecture" {
  description = "Runner binary architecture. `x64` for Intel/AMD machine families, `arm64` for the t2a/c4a families (must match `machine_types`)."
  type        = string
  default     = "x64"

  validation {
    condition     = contains(["x64", "arm64"], var.runner_architecture)
    error_message = "runner_architecture must be x64 or arm64."
  }
}

variable "instance_target_capacity_type" {
  description = "spot or on-demand. Maps to `scheduling.provisioning_model = SPOT` vs `STANDARD`."
  type        = string
  default     = "spot"

  validation {
    condition     = contains(["spot", "on-demand"], var.instance_target_capacity_type)
    error_message = "instance_target_capacity_type must be \"spot\" or \"on-demand\"."
  }
}

variable "disk" {
  description = "Boot disk for runner VMs."
  type = object({
    size_gb = optional(number, 100)
    type    = optional(string, "pd-balanced")
    kms_key = optional(string)
  })
  default = {}

  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd", "hyperdisk-balanced"], coalesce(var.disk.type, "pd-balanced"))
    error_message = "disk.type must be one of pd-standard, pd-balanced, pd-ssd, hyperdisk-balanced."
  }
}

variable "shielded_vm" {
  description = "Enable Shielded VM (secure boot, vTPM, integrity monitoring) on runner VMs."
  type        = bool
  default     = true
}

variable "runner_image_family" {
  description = "Compute Engine image family for runner VMs. Defaults to ubuntu-2404-lts-amd64 / ubuntu-2404-lts-arm64 based on runner_architecture."
  type        = string
  default     = null
}

variable "runner_image_project" {
  description = "Image project hosting `runner_image_family`. Default `ubuntu-os-cloud`."
  type        = string
  default     = "ubuntu-os-cloud"
}

###############################################################################
# Scaling / lifecycle (parity with AWS upstream)
###############################################################################

variable "runners_maximum_count" {
  description = "Maximum number of live runner VMs. Scale-up refuses to launch a new VM beyond this number (parity with AWS RUNNERS_MAXIMUM_COUNT)."
  type        = number
  default     = 1

  validation {
    condition     = var.runners_maximum_count >= 1
    error_message = "runners_maximum_count must be >= 1."
  }
}

variable "minimum_running_time_in_minutes" {
  description = "Minutes a runner must be up before scale-down may terminate it when idle (parity with AWS MINIMUM_RUNNING_TIME_IN_MINUTES)."
  type        = number
  default     = 3
}

variable "enable_ephemeral_runners" {
  description = "If true, runners use --ephemeral and self-terminate after one job."
  type        = bool
  default     = true
}

variable "enable_job_queued_check" {
  description = "If true, scale-up re-checks via the GitHub API that the workflow job is still queued before launching a VM."
  type        = bool
  default     = true
}

variable "enable_runner_workflow_job_labels_check_all" {
  description = <<-EOT
    If true, a workflow job is dispatched only when every label on the job is satisfied by the runner label set (exact-match semantics).
    If false, any single overlapping label triggers scale-up — risk of false positives from GitHub-hosted labels.
  EOT
  type        = bool
  default     = true
}

variable "runner_disable_default_labels" {
  description = "If true, runners are registered without the default GitHub labels (self-hosted/<os>/<arch>); only `runner_extra_labels` are applied."
  type        = bool
  default     = true
}

variable "runner_extra_labels" {
  description = "Extra labels for the GitHub runner registration. Use these in `runs-on` arrays."
  type        = list(string)
  default     = ["iac"]

  validation {
    condition     = var.runner_extra_labels != null && length(var.runner_extra_labels) > 0
    error_message = "runner_extra_labels must be a non-null, non-empty list."
  }
}

variable "repository_white_list" {
  description = "Repository full names (`owner/repo`) allowed to use these runners. Empty allows all repos the App has access to."
  type        = list(string)
  default     = []
}

variable "scale_down_schedule_expression" {
  description = "Cloud Scheduler unix-cron expression for the scale-down job. Default every 5 minutes (parity with AWS default)."
  type        = string
  default     = "*/5 * * * *"
}

variable "runner_binaries_syncer_schedule_expression" {
  description = "Cloud Scheduler cron for the binaries syncer. Default once a day."
  type        = string
  default     = "0 4 * * *"
}

variable "scheduler_time_zone" {
  description = "IANA time zone string for the Cloud Scheduler jobs."
  type        = string
  default     = "Etc/UTC"
}

variable "runner_idle_self_destruct_minutes" {
  description = "Self-destruct timer the startup script arms; if no job arrives within this many minutes the VM deletes itself. Defends against orphaned VMs when scale-down is delayed."
  type        = number
  default     = 30
}

###############################################################################
# Cloud Run sizing
###############################################################################

variable "webhook_min_instances" {
  description = "Minimum Cloud Run instances for the webhook service. Set >0 to avoid cold starts on first webhook delivery."
  type        = number
  default     = 0
}

variable "webhook_max_instances" {
  description = "Maximum Cloud Run instances for the webhook service."
  type        = number
  default     = 10
}

variable "scale_up_max_instances" {
  description = "Maximum Cloud Run instances for the scale-up service (Pub/Sub-push concurrency)."
  type        = number
  default     = 5
}

variable "scale_up_concurrency" {
  description = "Per-instance concurrency for the scale-up service. 1 keeps each Pub/Sub message single-threaded which simplifies the runners_maximum_count guard."
  type        = number
  default     = 1
}

variable "request_timeout_seconds" {
  description = "Request timeout for the scale-up / scale-down / binaries-syncer Cloud Run services. Webhook uses a separate, smaller timeout (5s)."
  type        = number
  default     = 300
}

###############################################################################
# Logging / observability
###############################################################################

variable "logging_retention_in_days" {
  description = "Retention (days) for the per-service log bucket created in `region`. The control-plane services write to this bucket via a routing sink."
  type        = number
  default     = 14
}

variable "enable_audit_metrics" {
  description = "If true, create log-based metrics for webhook deliveries, scale-up successes/failures, and runner VM creations."
  type        = bool
  default     = true
}

###############################################################################
# Image overrides (digest-pinned defaults vendored in main.tf locals)
###############################################################################

variable "webhook_image" {
  description = "Optional override (image with digest) for the webhook Cloud Run service. Defaults to the digest pinned in locals.control_plane_images."
  type        = string
  default     = null
}

variable "scale_up_image" {
  description = "Optional override (image with digest) for the scale-up Cloud Run service."
  type        = string
  default     = null
}

variable "scale_down_image" {
  description = "Optional override (image with digest) for the scale-down Cloud Run service."
  type        = string
  default     = null
}

variable "runner_binaries_syncer_image" {
  description = "Optional override (image with digest) for the runner-binaries-syncer Cloud Run service."
  type        = string
  default     = null
}

###############################################################################
# Encryption
###############################################################################

variable "kms_key_self_link" {
  description = "Optional CMEK applied to the GCS binaries bucket, Pub/Sub topics, and runner instance template boot disks. Format `projects/<p>/locations/<r>/keyRings/<kr>/cryptoKeys/<k>`. The relevant Google service agents must be granted roles/cloudkms.cryptoKeyEncrypterDecrypter on this key by the caller."
  type        = string
  default     = null
}
