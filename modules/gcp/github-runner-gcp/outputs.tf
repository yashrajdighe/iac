output "webhook_endpoint" {
  description = "POST URL for the GitHub App webhook. Configure this as the Payload URL with content-type application/json."
  value       = google_cloud_run_v2_service.webhook.uri
}

output "webhook" {
  description = "Webhook Cloud Run service details (parity with AWS module's `webhook` output)."
  value = {
    endpoint        = google_cloud_run_v2_service.webhook.uri
    service_name    = google_cloud_run_v2_service.webhook.name
    service_account = google_service_account.webhook.email
  }
}

output "runners" {
  description = "Runner fleet resources (parity with AWS module's `runners` output)."
  value = {
    instance_template_self_link = google_compute_instance_template.runner.self_link
    service_account_email       = google_service_account.runner.email
    scale_up_service_account    = google_service_account.scale_up.email
    scale_down_service_account  = google_service_account.scale_down.email
  }
}

output "queues" {
  description = "Build job Pub/Sub topics and subscription (parity with AWS module's `queues` output)."
  value = {
    topic            = google_pubsub_topic.build_jobs.id
    dlq_topic        = google_pubsub_topic.build_jobs_dlq.id
    subscription     = google_pubsub_subscription.build_jobs.id
    topic_name       = google_pubsub_topic.build_jobs.name
    dlq_topic_name   = google_pubsub_topic.build_jobs_dlq.name
    subscription_id  = google_pubsub_subscription.build_jobs.name
    push_endpoint_sa = google_service_account.invoker.email
  }
}

output "runner_binaries_bucket" {
  description = "GCS bucket caching the actions/runner tarball."
  value       = google_storage_bucket.runner_binaries.name
}

output "control_plane_images" {
  description = "Container images (with digest) actually deployed to each Cloud Run service. Useful for image-rollback runbooks."
  value       = local.resolved_images
}

output "github_app_installation_id_from_secret" {
  description = "Installation ID resolved from `github_app_installation_id_secret_id` when supplied (parity with AWS output of the same shape)."
  value       = try(data.google_secret_manager_secret_version.installation_id[0].secret_data, null)
  sensitive   = true
}
