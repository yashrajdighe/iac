output "arn" {
  description = "ACM certificate ARN."
  value       = aws_acm_certificate.this.arn
}

output "id" {
  description = "ACM certificate ID."
  value       = aws_acm_certificate.this.id
}

output "domain_name" {
  description = "Primary domain (first entry in var.domains)."
  value       = aws_acm_certificate.this.domain_name
}

output "subject_alternative_names" {
  description = "SANs on the issued certificate (all domains after the primary)."
  value       = aws_acm_certificate.this.subject_alternative_names
}

output "domain_validation_options" {
  description = "DNS validation records; create these (e.g. in Route 53 or another DNS provider) before the certificate can issue."
  value       = aws_acm_certificate.this.domain_validation_options
}

output "status" {
  description = "Certificate status in ACM (e.g. PENDING_VALIDATION, ISSUED)."
  value       = aws_acm_certificate.this.status
}
