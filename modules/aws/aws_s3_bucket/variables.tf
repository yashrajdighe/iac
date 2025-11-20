variable "create_s3_bucket" {
  type        = bool
  default     = true
  description = "Flag to create the S3 bucket."
}

variable "name" {
  type        = string
  default     = ""
  description = "Name of the S3 bucket."
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "enable_retention" {
  description = "enable retention on this bucket"
  type        = bool
  default     = false
}

variable "retention_days" {
  description = "Number of days to retain the data inside the bucket."
  type        = number
  default     = 7
}
