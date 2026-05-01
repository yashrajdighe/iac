###############################################################################
# Pub/Sub: build-jobs topic + DLQ + push subscription.
#
# webhook -> publishes to `build_jobs`
# build_jobs -> push subscription -> scale-up Cloud Run (OIDC-auth)
# After 5 deliveries that fail, the message is sent to `build_jobs_dlq`.
#
# Mirrors the SQS build queue + DLQ pair the AWS upstream creates.
###############################################################################

resource "google_pubsub_topic" "build_jobs" {
  project = var.project_id
  name    = local.topic_name
  labels  = local.labels

  message_retention_duration = "86400s"

  dynamic "message_storage_policy" {
    for_each = var.kms_key_self_link != null ? [1] : []
    content {
      allowed_persistence_regions = [var.region]
    }
  }

  kms_key_name = var.kms_key_self_link
}

resource "google_pubsub_topic" "build_jobs_dlq" {
  project = var.project_id
  name    = local.dlq_topic_name
  labels  = local.labels

  message_retention_duration = "604800s" # 7 days; long enough for human triage.

  dynamic "message_storage_policy" {
    for_each = var.kms_key_self_link != null ? [1] : []
    content {
      allowed_persistence_regions = [var.region]
    }
  }

  kms_key_name = var.kms_key_self_link
}

resource "google_pubsub_subscription" "build_jobs" {
  project = var.project_id
  name    = local.subscription_name
  topic   = google_pubsub_topic.build_jobs.name
  labels  = local.labels

  # Ack deadline must comfortably exceed scale-up's worst-case latency
  # (token mint + JIT config + instances.insert ~= 10-15s typical).
  ack_deadline_seconds       = 60
  message_retention_duration = "86400s"

  enable_message_ordering = false

  expiration_policy {
    ttl = "" # never expire
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.build_jobs_dlq.id
    max_delivery_attempts = 5
  }

  push_config {
    push_endpoint = google_cloud_run_v2_service.scale_up.uri

    oidc_token {
      service_account_email = google_service_account.invoker.email
      audience              = google_cloud_run_v2_service.scale_up.uri
    }

    attributes = {
      x-goog-version = "v1"
    }
  }

  depends_on = [
    google_cloud_run_v2_service_iam_member.invoker_can_invoke_scale_up,
  ]
}

###############################################################################
# Runner binaries cache bucket.
###############################################################################

resource "google_storage_bucket" "runner_binaries" {
  project                     = var.project_id
  name                        = local.binaries_bucket_name
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
  labels                      = local.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  dynamic "encryption" {
    for_each = var.kms_key_self_link != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_self_link
    }
  }
}
