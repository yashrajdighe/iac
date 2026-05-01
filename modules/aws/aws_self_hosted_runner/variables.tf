variable "aws_region" {
  description = "Region where runner infrastructure is deployed (must match the default AWS provider region)."
  type        = string
}

variable "vpc_id" {
  description = "VPC for runner security groups and networking."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for runner instances (public subnets with map_public_ip_on_launch are supported)."
  type        = list(string)
}

variable "github_app_private_key_secret_arn" {
  description = "Secrets Manager secret ARN (or id) holding the GitHub App private key as base64-encoded PEM (same encoding as key_base64_ssm had)."
  type        = string
}

variable "github_app_id_ssm_parameter_name" {
  description = "SSM parameter name or full parameter ARN for the GitHub App ID (same AWS region as aws_region / default provider)."
  type        = string
}

variable "github_webhook_secret_arn" {
  description = "Secrets Manager secret ARN (or id) for the GitHub App webhook secret (same region as aws_region)."
  type        = string
}

variable "github_app_installation_id_ssm_parameter_name" {
  description = "Optional SSM parameter name or ARN for installation ID (not used by github-aws-runners; read to expose output github_app_installation_id_from_ssm)."
  type        = string
  default     = null
}

variable "repository_white_list" {
  description = "Repository full names (owner/repo) allowed to use the runners; empty allows all repos the app can access."
  type        = list(string)
  default     = []
}

variable "prefix" {
  description = "Resource name prefix for the upstream module."
  type        = string
  default     = "github-actions"
}

variable "runner_disable_default_labels" {
  description = "When true, runners do not get default GitHub labels (self-hosted, os, arch); only runner_extra_labels are used (upstream runner_disable_default_labels)."
  type        = bool
  default     = true
}

variable "runner_extra_labels" {
  description = "GitHub runner labels when default labels are disabled, or extra labels when defaults are enabled (upstream runner_extra_labels). Use runs-on in workflows that list every label here if enable_runner_workflow_job_labels_check_all is true."
  type        = list(string)
  default     = ["iac"]

  validation {
    condition     = var.runner_extra_labels != null && length(var.runner_extra_labels) > 0
    error_message = "runner_extra_labels must be a non-null, non-empty list when using custom-only labels."
  }
}

variable "block_device_mappings" {
  description = "Root EBS volumes for runner instances (passed through to github-aws-runners)."
  type = list(object({
    delete_on_termination = optional(bool, true)
    device_name           = optional(string, "/dev/xvda")
    encrypted             = optional(bool, true)
    iops                  = optional(number)
    kms_key_id            = optional(string)
    snapshot_id           = optional(string)
    throughput            = optional(number)
    volume_size           = number
    volume_type           = optional(string, "gp3")
  }))
  default = [{
    volume_size = 100
    volume_type = "gp3"
    iops        = 6000
    throughput  = 500
  }]
}

variable "instance_types" {
  description = "EC2 instance types for the runner fleet."
  type        = list(string)
  default     = ["c5.large", "m5.large"]
}

variable "instance_target_capacity_type" {
  description = "spot or on-demand."
  type        = string
  default     = "spot"

  validation {
    condition     = contains(["spot", "on-demand"], var.instance_target_capacity_type)
    error_message = "instance_target_capacity_type must be \"spot\" or \"on-demand\"."
  }
}

variable "enable_ephemeral_runners" {
  description = "If true, each runner serves a single job then terminates (recommended with Spot)."
  type        = bool
  default     = true
}

variable "enable_job_queued_check" {
  description = "If true, scale-up calls the GitHub API and only launches when the workflow job is still queued. Reduces duplicate EC2 when ephemeral defaults would disable this (upstream enable_job_queued_check)."
  type        = bool
  default     = true
}

variable "enable_runner_workflow_job_labels_check_all" {
  description = <<-EOT
    If true, a workflow job is dispatched only when every label on the job is satisfied by the runner label set (upstream enable_runner_workflow_job_labels_check_all / webhook exactMatch).
    If false, any single overlapping label (e.g. linux, x64) matches — GitHub-hosted jobs such as ubuntu-latest also use those labels, so they can incorrectly trigger self-hosted scale-up.
  EOT
  type        = bool
  default     = true
}

variable "runners_maximum_count" {
  description = "Maximum number of runner instances the scale-up path will create (upstream RUNNERS_MAXIMUM_COUNT / runners_maximum_count)."
  type        = number
  default     = 1
}

variable "logging_retention_in_days" {
  description = "CloudWatch Logs retention for GitHub runner Lambda log groups (upstream logging_retention_in_days)."
  type        = number
  default     = 14
}

variable "minimum_running_time_in_minutes" {
  description = <<-EOT
    Minutes a runner must be up before scale-down may terminate it when idle (upstream MINIMUM_RUNNING_TIME_IN_MINUTES).
    Unset upstream defaults to 5 (linux) or 15 (windows). Low values risk terminating before registration completes.
  EOT
  type        = number
  default     = 3
}

variable "scale_down_schedule_expression" {
  description = "EventBridge schedule for scale-down checks."
  type        = string
  default     = "cron(*/5 * * * ? *)"
}

variable "scale_up_reserved_concurrent_executions" {
  description = <<-EOT
    Reserved executions for the scale-up Lambda (-1 = no reservation, shares account unreserved capacity).
    A positive value can trigger InvalidParameterValueException if unreserved concurrent executions would fall below 10.
  EOT
  type        = number
  default     = -1
}

variable "create_service_linked_role_spot" {
  description = "Create AWSServiceRoleForEC2Spot; defaults to true when instance_target_capacity_type is spot."
  type        = bool
  default     = null
}

variable "tags" {
  description = "Extra tags merged into resources created by the upstream module."
  type        = map(string)
  default     = {}
}
