output "records" {
  description = "Map of all created DNS records keyed by the input map key"
  value       = cloudflare_dns_record.this
}

output "record_ids" {
  description = "Map of DNS record IDs keyed by the input map key"
  value       = { for k, v in cloudflare_dns_record.this : k => v.id }
}

output "record_hostnames" {
  description = "Map of fully-qualified DNS record hostnames keyed by the input map key"
  value       = { for k, v in cloudflare_dns_record.this : k => v.name }
}
