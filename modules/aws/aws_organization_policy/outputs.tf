output "id" {
  description = "The ID of the SCP policy. Null if not enabled."
  value       = try(aws_organizations_policy.this[0].id, null)
}

output "arn" {
  description = "The ARN of the SCP policy. Null if not enabled."
  value       = try(aws_organizations_policy.this[0].arn, null)
}
