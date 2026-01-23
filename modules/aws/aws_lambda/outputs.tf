output "function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  description = "The ARN to be used for invoking Lambda function from API Gateway."
  value       = aws_lambda_function.this.invoke_arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role created for the Lambda function."
  value       = var.create_role ? aws_iam_role.this[0].arn : null
}
