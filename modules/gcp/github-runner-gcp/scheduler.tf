###############################################################################
# Cloud Scheduler jobs.
#
# Replaces the AWS upstream's EventBridge rules:
#   - scale-down: cron parity with var.scale_down_schedule_expression.
#   - runner-binaries-syncer: daily refresh of the cached runner tarball.
#
# Both fire OIDC-authenticated POSTs at the corresponding internal-only
# Cloud Run service. The invoker SA carries `roles/run.invoker` on each
# service via services.tf.
###############################################################################

resource "google_cloud_scheduler_job" "scale_down" {
  project          = var.project_id
  region           = var.region
  name             = "${var.prefix}-scale-down"
  description      = "Trigger the scale-down service every ${var.scale_down_schedule_expression}."
  schedule         = var.scale_down_schedule_expression
  time_zone        = var.scheduler_time_zone
  attempt_deadline = "120s"

  retry_config {
    retry_count          = 1
    min_backoff_duration = "5s"
    max_backoff_duration = "30s"
  }

  http_target {
    http_method = "POST"
    uri         = google_cloud_run_v2_service.scale_down.uri

    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({ source = "cloud-scheduler" }))

    oidc_token {
      service_account_email = google_service_account.invoker.email
      audience              = google_cloud_run_v2_service.scale_down.uri
    }
  }

  depends_on = [
    google_cloud_run_v2_service_iam_member.invoker_can_invoke_scale_down,
  ]
}

resource "google_cloud_scheduler_job" "runner_binaries_syncer" {
  project          = var.project_id
  region           = var.region
  name             = "${var.prefix}-runner-binaries-syncer"
  description      = "Refresh the GCS-cached actions/runner tarball."
  schedule         = var.runner_binaries_syncer_schedule_expression
  time_zone        = var.scheduler_time_zone
  attempt_deadline = "${var.request_timeout_seconds}s"

  retry_config {
    retry_count          = 1
    min_backoff_duration = "30s"
    max_backoff_duration = "300s"
  }

  http_target {
    http_method = "POST"
    uri         = google_cloud_run_v2_service.runner_binaries_syncer.uri

    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({ source = "cloud-scheduler" }))

    oidc_token {
      service_account_email = google_service_account.invoker.email
      audience              = google_cloud_run_v2_service.runner_binaries_syncer.uri
    }
  }

  depends_on = [
    google_cloud_run_v2_service_iam_member.invoker_can_invoke_binaries,
  ]
}
