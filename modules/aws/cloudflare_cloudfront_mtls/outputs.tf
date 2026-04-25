output "lambda_function_arn" {
  description = "ARN of the rotator Lambda."
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "Name of the rotator Lambda."
  value       = aws_lambda_function.this.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.this.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role (used by per-env S3 trust-store policies)."
  value       = aws_iam_role.this.name
}

output "root_ca_secret_arn" {
  description = "ARN of the Secrets Manager secret for the custom root CA (PEM + key)."
  value       = aws_secretsmanager_secret.root_ca.arn
}

output "client_cert_secret_arn" {
  description = "ARN of the Secrets Manager secret for the Cloudflare client cert and metadata."
  value       = aws_secretsmanager_secret.client.arn
}

output "event_rule_name" {
  description = "EventBridge rule name for the rotation schedule."
  value       = aws_cloudwatch_event_rule.rotation.name
}
