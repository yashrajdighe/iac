variable "aws_region" {
  description = "Region where runner infrastructure is deployed (must match the default AWS provider region)."
  type        = string
}

variable "vpc_id" {
  description = "VPC for runner security groups and networking."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for runner instances (each in a different AZ per upstream requirements)."
  type        = list(string)
}

variable "github_app_private_key_secret_arn" {
  description = "Secrets Manager secret ARN (or id) holding the GitHub App private key as base64-encoded PEM (same encoding as key_base64_ssm had)."
  type        = string
}

variable "github_app_id_ssm_parameter_name" {
  description = "SSM parameter name or full parameter ARN for the GitHub App ID (credentials region; API accepts either)."
  type        = string
}

variable "github_webhook_secret_arn" {
  description = "Secrets Manager secret ARN (or id) for the GitHub App webhook secret (credentials region)."
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
