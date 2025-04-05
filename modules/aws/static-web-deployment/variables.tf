variable "create_static_web_deployment" {
  description = "Whether to create the static web deployment resources"
  type        = bool
  default     = true
}

variable "static_web_deployment_name" {
  description = "Name of the static web deployment"
  type        = string
}

variable "enable_cloudfront_distribution" {
  description = "Whether to enable CloudFront distribution"
  type        = bool
  default     = true
}

variable "origins" {
  description = "List of origins for the static web deployment"
  type = list(object({
    path          = string
    origin_id     = string
    bucket_suffix = string
  }))
}

variable "default_cache_behavior" {
  description = "Default cache behavior for the CloudFront distribution"
  type = object({
    target_origin_id = string
  })

}

variable "ordered_cache_behaviors" {
  description = "List of ordered cache behaviors for the CloudFront distribution"
  type = list(object({
    path_pattern     = string
    target_origin_id = string
  }))
}

variable "default_root_object" {
  description = "Default root object for the CloudFront distribution"
  type        = string
  default     = "index.html"

}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}
