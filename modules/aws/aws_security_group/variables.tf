variable "create_security_group" {
  description = "Whether to create the security group and its rules. Set to false to skip resource creation."
  type        = bool
  default     = true
}
variable "name" {
  description = "Name of the security group."
  type        = string
}

variable "description" {
  description = "Description of the security group."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID to associate with the security group."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "ingress_rules" {
  description = "List of ingress rule objects."
  type = list(object({
    cidr_ipv4   = optional(string)
    cidr_ipv6   = optional(string)
    from_port   = number
    to_port     = number
    ip_protocol = string
    description = optional(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rule objects."
  type = list(object({
    cidr_ipv4   = optional(string)
    cidr_ipv6   = optional(string)
    from_port   = optional(number)
    to_port     = optional(number)
    ip_protocol = string
    description = optional(string)
  }))
  default = []
}
