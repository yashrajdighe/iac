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
  default = []
}

variable "default_root_object" {
  description = "Default root object for the CloudFront distribution"
  type        = string
  default     = "index.html"

}

variable "aliases" {
  description = "Alternate domain names (CNAMEs) for the CloudFront distribution. The ACM certificate in us-east-1 must include these as CN/SAN. Leave empty to use the default *.cloudfront.net domain only."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate in us-east-1 for custom domain names. Required when `aliases` is non-empty. Ignored when `aliases` is empty."
  type        = string
  default     = ""
}

variable "cloudfront_ssl_minimum_protocol_version" {
  description = "Minimum TLS version for viewer connections when using a custom ACM certificate (`aliases` non-empty). Ignored with the default CloudFront certificate."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "cloudfront_viewer_request_function_runtime" {
  description = "Runtime for the CloudFront viewer-request function (directory slash redirect and index.html rewrite)"
  type        = string
  default     = "cloudfront-js-2.0"
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}

variable "github_org_name" {
  description = "Github org name"
  type        = string
  default     = "yashrajdighe"
}

variable "github_repo_name" {
  description = "Github repo name"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "cloudflare_api_token_secret_arn" {
  description = "Cloudflare API token secret arn"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "Cross-account KMS key ARN for decrypt access"
  type        = string
  default     = ""
}

variable "create_mtls_trust_store" {
  description = "If true, create a dedicated S3 bucket for the Cloudflare origin mTLS root CA (root-ca.pem) and allow the rotator role to Put/Get the object (cross-account)."
  type        = bool
  default     = false
}

variable "mtls_rotator_account_id" {
  description = "AWS account ID of the org common account that runs the Cloudflare origin cert rotator Lambda (for bucket policy principal)."
  type        = string
  default     = ""
}

variable "mtls_rotator_role_name" {
  description = "IAM role *name* only (not the full ARN), for the rotator Lambda in the common account. Must match the deployed role: if the rotator uses resource_name_prefix, the name is {prefix}{function_name}-role (e.g. devops-playground-in-cloudflare-origin-cert-rotator-role). Mismatches cause S3 PutBucketPolicy errors like Invalid principal."
  type        = string
  default     = ""
}

variable "mtls_trust_store_bucket_name" {
  description = "Override S3 bucket name for mTLS root CA. If empty, static_web_deployment_name-mtls-trust-store is used (see local.mtls_trust_store_name)."
  type        = string
  default     = ""
}

variable "mtls_trust_store_object_key" {
  description = "S3 object key for the root CA public PEM. Must match the common-account rotator module input trust_store_s3_object_key."
  type        = string
  default     = "root-ca.pem"
}
