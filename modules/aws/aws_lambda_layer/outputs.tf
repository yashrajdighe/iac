output "layer_arn" {
  description = "The ARN of the Lambda Layer version."
  value       = aws_lambda_layer_version.this.arn
}

output "layer_version" {
  description = "The version of the Lambda Layer."
  value       = aws_lambda_layer_version.this.version
}
