variable "aws_service_access_principals" {
  description = "List of AWS service principal names for which you want to enable integration with your organization"
  type        = list(string)
  default = [
    "member.org.stacksets.cloudformation.amazonaws.com",
    "sso.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
  ]
}

variable "feature_set" {
  description = "Specify 'ALL' or 'CONSOLIDATED_BILLING' to determine the functionality that is available to the organization"
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ALL", "CONSOLIDATED_BILLING"], var.feature_set)
    error_message = "The feature_set value must be either 'ALL' or 'CONSOLIDATED_BILLING'."
  }
}

variable "enabled_policy_types" {
  description = "List of policy types to enable in the organization. Defaults to all available policy types."
  type        = list(string)
  default = [
    "SERVICE_CONTROL_POLICY",
    # "TAG_POLICY",
    # "BACKUP_POLICY",
    # "AISERVICES_OPT_OUT_POLICY",
  ]
}
