output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.this.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.this.arn
}

output "kms_key_alias_name" {
  description = "Alias name for the KMS key (null if alias is not created)"
  value       = try(aws_kms_alias.this[0].name, null)
}
