output "id" {
  description = "The ID of the SCP policy."
  value       = aws_organizations_policy.this.id
}

output "arn" {
  description = "The ARN of the SCP policy."
  value       = aws_organizations_policy.this.arn
}
