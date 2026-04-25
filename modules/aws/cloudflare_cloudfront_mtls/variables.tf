variable "function_name" {
  description = "Name of the Lambda that rotates the Cloudflare origin client certificate."
  type        = string
  default     = "cloudflare-origin-cert-rotator"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID (v4 API)."
  type        = string
}

variable "cloudflare_api_token_secret_arn" {
  description = "Secrets Manager secret ARN for CLOUDFLARE_API_TOKEN in the same account (common)."
  type        = string
}

variable "trust_store_s3_object_key" {
  description = "S3 object key for the public root CA PEM in each trust-store bucket (e.g. root-ca.pem or mtls/root-ca.pem). Must match static_web_deployment's mtls_trust_store_object_key."
  type        = string
  default     = "root-ca.pem"
}

variable "trust_store_bucket_arns" {
  description = "S3 bucket ARNs (e.g. arn:aws:s3:::bucket) for per-env mTLS root CA trust stores."
  type        = list(string)

  validation {
    condition     = length(var.trust_store_bucket_arns) > 0
    error_message = "At least one trust_store_bucket_arn is required (dev/staging/prod S3 trust-store buckets)."
  }
}

variable "lambda_layer_arn" {
  description = "Lambda layer with cryptography and requests (e.g. prBotSecurityLibrary)."
  type        = string
}

variable "client_cert_validity_days" {
  description = "Client certificate lifetime in days."
  type        = number
  default     = 30
}

variable "root_ca_validity_days" {
  description = "Root CA certificate lifetime in days (e.g. 3650 for 10 years)."
  type        = number
  default     = 3650
}

variable "root_ca_renew_before_days" {
  description = "When the stored root CA's notAfter is within this many days (or already past), the Lambda auto-rotates the root and re-uploads to S3. Must be less than root_ca_validity_days (enforced in main.tf). With a 28-day EventBridge schedule, 120+ days allows several invocations before notAfter."
  type        = number
  default     = 120
}

variable "rotation_schedule" {
  description = "EventBridge schedule (e.g. rate(28 days) or cron(...))."
  type        = string
  default     = "rate(28 days)"
}

variable "secret_recovery_window_in_days" {
  description = "Secrets Manager recovery window for the rotator-owned secrets. Use 0 to delete immediately in non-prod, or 7–30."
  type        = number
  default     = 7
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days for the Lambda log group."
  type        = number
  default     = 14
}

variable "lambda_memory_size" {
  type    = number
  default = 256
}

variable "lambda_timeout" {
  type    = number
  default = 60
}

variable "secret_name_prefix" {
  description = "Prefix for Secrets Manager names created in this account (no leading slash required)."
  type        = string
  default     = "cloudflare-origin-mtls"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources in this module."
}
