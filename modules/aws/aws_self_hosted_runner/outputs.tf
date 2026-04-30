output "webhook" {
  description = "Webhook API resources; use endpoint in the GitHub App settings."
  value       = module.github_runners.webhook
}

output "runners" {
  description = "Runner fleet (launch template, scale lambdas, IAM roles)."
  value       = module.github_runners.runners
}

output "queues" {
  description = "Build job SQS queues."
  value       = module.github_runners.queues
}

output "webhook_endpoint" {
  description = "POST URL to configure as the GitHub App webhook."
  value       = module.github_runners.webhook.endpoint
}

output "github_app_installation_id_from_ssm" {
  description = "Installation ID from SSM when github_app_installation_id_ssm_parameter_name was set (upstream module derives installs from the app; this is for reference)."
  value       = try(data.aws_ssm_parameter.github_app_installation_id[0].value, null)
  sensitive   = false
}
