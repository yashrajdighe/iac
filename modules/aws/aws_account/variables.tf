variable "account_name" {
  description = "Name of the AWS account to be created"
  type        = string
}

variable "account_email" {
  description = "Email address for the AWS account"
  type        = string
}

variable "organization_role_name" {
  description = "Name of the IAM role that should be created in the new account"
  type        = string
  default     = "OrganizationAccountAccessRole"
}
