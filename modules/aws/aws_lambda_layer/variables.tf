variable "layer_name" {
  description = "The name of the Lambda Layer."
  type        = string
}

variable "source_path" {
  description = "The local path to the Lambda Layer's content."
  type        = string
}

variable "compatible_runtimes" {
  description = "A list of compatible runtimes for the Lambda Layer."
  type        = list(string)
  default     = []
}

variable "description" {
  description = "A description for the Lambda Layer."
  type        = string
  default     = null
}

variable "license_info" {
  description = "License information for the Lambda Layer."
  type        = string
  default     = null
}
