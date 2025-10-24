variable "name" {
  description = "Name of the cloudformation stackset."
  type        = string
}

variable "template_url" {
  description = "The URL of the CloudFormation template in S3."
  type        = string
}
