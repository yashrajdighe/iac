variable "create_ssh_key_pair" {
  description = "Whether to create the SSH key pair."
  type        = bool
  default     = true
}

variable "key_name" {
  description = "The name of the SSH key pair."
  type        = string
}

variable "public_key" {
  description = "The public key material in OpenSSH format."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the key pair."
  type        = map(string)
  default     = {}
}
