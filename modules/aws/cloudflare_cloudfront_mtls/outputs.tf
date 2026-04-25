output "lambda_function_arn" {
  description = "ARN of the rotator Lambda, or null if create is false."
  value       = try(aws_lambda_function.this[0].arn, null)
}

output "lambda_function_name" {
  description = "Name of the rotator Lambda, or null if create is false."
  value       = try(aws_lambda_function.this[0].function_name, null)
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role, or null if create is false."
  value       = try(aws_iam_role.this[0].arn, null)
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role (used by per-env S3 trust-store policies), or null if create is false."
  value       = try(aws_iam_role.this[0].name, null)
}

output "root_ca_secret_arn" {
  description = "ARN of the Secrets Manager secret for the custom root CA (PEM + key), or null if create is false."
  value       = try(aws_secretsmanager_secret.root_ca[0].arn, null)
}

output "client_cert_secret_arn" {
  description = "ARN of the Secrets Manager secret for the Cloudflare client cert and metadata, or null if create is false."
  value       = try(aws_secretsmanager_secret.client[0].arn, null)
}

output "event_rule_name" {
  description = "EventBridge rule name for the rotation schedule, or null if create is false."
  value       = try(aws_cloudwatch_event_rule.rotation[0].name, null)
}

output "resource_name_prefix" {
  description = "Effective prefix applied to resource names (normalized trailing hyphen), or empty string."
  value       = local.resource_prefix
}

output "trust_store_s3_object_key" {
  description = "Resolved S3 object key for the public root CA (var.trust_store_s3_object_key or default from resource_name_prefix + root-ca.pem)."
  value       = local.trust_store_s3_object_key
}

output "create" {
  description = "Whether the module created rotator resources."
  value       = var.create
}

output "lambda_layer_arn" {
  description = "Lambda layer ARN actually attached (lambda_layer_name + lambda_layer_version)."
  value       = try(data.aws_lambda_layer_version.lambda_deps[0].arn, null)
}

output "lambda_layer_version" {
  description = "Lambda layer version attached (var.lambda_layer_version)."
  value       = var.create ? var.lambda_layer_version : null
}
