output "organization_id" {
  description = "Identifier of the organization"
  value       = aws_organizations_organization.org.id
}

output "organization_arn" {
  description = "ARN of the organization"
  value       = aws_organizations_organization.org.arn
}

output "organization_master_account_id" {
  description = "Management account ID"
  value       = aws_organizations_organization.org.master_account_id
}

output "organization_roots" {
  description = "List of organization roots"
  value       = aws_organizations_organization.org.roots
}
