variable "create" {
  description = "If false, no AWS resources in this module are created (e.g. to disable the rotator in a stack). Set false only when you can omit the Cloudflare/Trust-store inputs or pass null/empty; see the module check block for required values when create is true."
  type        = bool
  default     = true
}

variable "resource_name_prefix" {
  description = "Optional prefix for all named resources in this module (Lambda, IAM role/policies, CloudWatch log group and rule, Secrets Manager secret path). Empty string preserves legacy names. Ending hyphens are normalized; e.g. 'acme' and 'acme-' both become 'acme-'. After changing this, update static_web_deployment mtls_rotator_role_name to match output lambda_role_name."
  type        = string
  default     = ""
}

variable "function_name" {
  description = "Base Lambda name; the deployed function name is resource_name_prefix (if any) plus this value, per locals.lambda_function_name."
  type        = string
  default     = "cloudflare-origin-cert-rotator"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID (v4 API). Required when create is true; may be null when create is false."
  type        = string
  default     = null
  nullable    = true
}

variable "cloudflare_zone_name" {
  description = "Zone apex hostname (e.g. example.com). If set, the rotator uses it for AOP cert CN/SAN and skips GET /zones/{id}, which requires Zone read on the API token. Recommended for tokens scoped only to SSL/certificates."
  type        = string
  default     = null
  nullable    = true
}

variable "cloudflare_api_token_secret_arn" {
  description = "Secrets Manager secret ARN for CLOUDFLARE_API_TOKEN in the same account (common). Required when create is true; may be null when create is false."
  type        = string
  default     = null
  nullable    = true
}

variable "trust_store_s3_object_key" {
  description = "S3 object key for the public root CA PEM. Leave null to use the default: normalized resource_name_prefix plus root-ca.pem (e.g. myprefix-root-ca.pem, or root-ca.pem if prefix is empty). Must match static_web_deployment mtls_trust_store_object_key."
  type        = string
  default     = null
  nullable    = true
}

variable "trust_store_bucket_arns" {
  description = "S3 bucket ARNs (e.g. arn:aws:s3:::bucket) for per-env mTLS root CA trust stores. When create is true, at least one ARN is required; use [] when create is false."
  type        = list(string)
  default     = []
}

variable "lambda_layer_arn" {
  description = "Full ARN of the Lambda layer *version* to attach (include the trailing :<version>). Prefer the layer stack output (e.g. aws_lambda_layer) so the version always exists. Do not use a data source with a guessed version number."
  type        = string
  default     = null
  nullable    = true
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
