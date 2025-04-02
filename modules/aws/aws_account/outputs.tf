output "account_id" {
  description = "The AWS account ID"
  value       = aws_organizations_account.account.id
}

output "account_arn" {
  description = "The ARN of the AWS account"
  value       = aws_organizations_account.account.arn
}

output "organization_role_name" {
  description = "The name of the created IAM role"
  value       = aws_organizations_account.account.role_name
}
