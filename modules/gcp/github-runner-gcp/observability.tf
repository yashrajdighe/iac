###############################################################################
# Optional log-based metrics for the control-plane services.
#
# Created when var.enable_audit_metrics is true. Consumers wire alerting
# policies on top of these metrics (alerting policies themselves are out of
# scope so callers can integrate with their existing notification channels).
###############################################################################

resource "google_logging_metric" "webhook_received" {
  count   = var.enable_audit_metrics ? 1 : 0
  project = var.project_id
  name    = "${var.prefix}/webhook_received"
  filter  = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${google_cloud_run_v2_service.webhook.name}"
    httpRequest.status=200
  EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "scale_up_failures" {
  count   = var.enable_audit_metrics ? 1 : 0
  project = var.project_id
  name    = "${var.prefix}/scale_up_failures"
  filter  = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${google_cloud_run_v2_service.scale_up.name}"
    severity>=ERROR
  EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "runner_vm_created" {
  count   = var.enable_audit_metrics ? 1 : 0
  project = var.project_id
  name    = "${var.prefix}/runner_vm_created"
  filter  = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${google_cloud_run_v2_service.scale_up.name}"
    jsonPayload.message="scale-up succeeded"
  EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}
