variable "name" {
  description = "The name of the SCP policy."
  type        = string
}

variable "description" {
  description = "The description of the SCP policy."
  type        = string
  default     = "Managed by Terraform"
}

variable "policy_content" {
  description = "Policy statement block for the SCP. Should be a map with keys: effect, actions, resources, principal (optional), conditions (optional)."
  type = object({
    effect     = string
    actions    = list(string)
    resources  = list(string)
    principal  = optional(any)
    conditions = optional(any)
  })
}

variable "policy_attachments" {
  description = "A list of AWS Organization IDs to attach the SCP to."
  type        = list(string)
  default     = []
}

variable "enabled" {
  description = "Whether to enable (create) the policy and its attachments."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the policy."
  type        = map(string)
  default     = {}
}
