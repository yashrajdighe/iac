variable "description" {
  description = "Description of the KMS CMK"
  type        = string
  default     = "Customer managed KMS key"
}

variable "enable_key_rotation" {
  description = "Whether key rotation is enabled"
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "Waiting period before KMS key deletion"
  type        = number
  default     = 20
}

variable "alias_name" {
  description = "KMS alias name (must start with alias/). Leave empty to skip alias creation"
  type        = string
  default     = ""
}

variable "allowed_use_role_arn" {
  description = "IAM role ARNs allowed to use this key. Leave empty to skip the allow-use statement"
  type        = list(string)
  default     = []
}
