variable "aws_service_access_principals" {
  description = "List of AWS service principal names for which you want to enable integration with your organization"
  type        = list(string)
  default = [
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
