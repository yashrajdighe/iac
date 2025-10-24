variable "name" {
  description = "Name of the cloudformation stackset."
  type        = string
}

variable "template_url" {
  description = "The URL of the CloudFormation template in S3."
  type        = string
}

variable "organizational_unit_ids" {
  description = "List of organizational unit IDs where stack instances will be deployed."
  type        = list(string)
}

variable "regions" {
  description = "List of AWS regions where stack instances will be deployed."
  type        = list(string)
}
