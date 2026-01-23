variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
}

variable "runtime" {
  description = "The runtime environment for the Lambda function."
  type        = string
}

variable "role_arn" {
  description = "The Amazon Resource Name (ARN) of the function's execution role. If not provided, a new role will be created."
  type        = string
  default     = null
}

variable "source_path" {
  description = "The local path to the Lambda function's code."
  type        = string
}

variable "environment_variables" {
  description = "A map of environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = "A list of Lambda Layer ARNs to attach to the function."
  type        = list(string)
  default     = []
}

variable "memory_size" {
  description = "The amount of memory to allocate to the function in MB."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "The amount of time that Lambda allows a function to run before stopping it. The default is 3 seconds."
  type        = number
  default     = 3
}

variable "description" {
  description = "A description of the function."
  type        = string
  default     = null
}

variable "create_role" {
  description = "Whether to create an IAM role for the Lambda function."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "The number of days to retain the CloudWatch logs. Default is 14 days."
  type        = number
  default     = 14
}

variable "additional_policy_arns" {
  description = "A list of additional policy ARNs to attach to the IAM role."
  type        = list(string)
  default     = []
}
