###############################################################################
# Cloud Run v2 services for the four control-plane components.
#
# Each service:
#   - runs the digest-pinned image from `local.resolved_images`
#   - uses its dedicated service account (created in iam.tf)
#   - receives the shared service_env map (resource references + flags)
#   - is internal-only except `webhook`, which is allUsers and verifies the
#     webhook signature inside the container before doing anything else
###############################################################################

locals {
  service_env_pairs = [
    for k, v in local.service_env : { name = k, value = v }
  ]
}

resource "google_cloud_run_v2_service" "webhook" {
  project             = var.project_id
  name                = local.service_names.webhook
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false
  labels              = local.labels

  template {
    service_account                  = google_service_account.webhook.email
    timeout                          = "5s"
    max_instance_request_concurrency = 80

    scaling {
      min_instance_count = var.webhook_min_instances
      max_instance_count = var.webhook_max_instances
    }

    containers {
      image = local.resolved_images.webhook

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
        cpu_idle = true
      }

      ports {
        container_port = 8080
      }

      dynamic "env" {
        for_each = local.service_env_pairs
        content {
          name  = env.value.name
          value = env.value.value
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service" "scale_up" {
  project             = var.project_id
  name                = local.service_names.scale_up
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  deletion_protection = false
  labels              = local.labels

  template {
    service_account                  = google_service_account.scale_up.email
    timeout                          = "${var.request_timeout_seconds}s"
    max_instance_request_concurrency = var.scale_up_concurrency

    scaling {
      min_instance_count = 0
      max_instance_count = var.scale_up_max_instances
    }

    containers {
      image = local.resolved_images.scale_up

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }

      ports {
        container_port = 8080
      }

      dynamic "env" {
        for_each = local.service_env_pairs
        content {
          name  = env.value.name
          value = env.value.value
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service" "scale_down" {
  project             = var.project_id
  name                = local.service_names.scale_down
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  deletion_protection = false
  labels              = local.labels

  template {
    service_account                  = google_service_account.scale_down.email
    timeout                          = "${var.request_timeout_seconds}s"
    max_instance_request_concurrency = 1

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = local.resolved_images.scale_down

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }

      ports {
        container_port = 8080
      }

      dynamic "env" {
        for_each = local.service_env_pairs
        content {
          name  = env.value.name
          value = env.value.value
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service" "runner_binaries_syncer" {
  project             = var.project_id
  name                = local.service_names.binaries
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  deletion_protection = false
  labels              = local.labels

  template {
    service_account                  = google_service_account.binaries.email
    timeout                          = "${var.request_timeout_seconds}s"
    max_instance_request_concurrency = 1

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = local.resolved_images.runner_binaries_syncer

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
        cpu_idle = true
      }

      ports {
        container_port = 8080
      }

      dynamic "env" {
        for_each = local.service_env_pairs
        content {
          name  = env.value.name
          value = env.value.value
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

###############################################################################
# Cloud Run invoker IAM.
#
# - webhook is allUsers (signature-verified inside the container).
# - scale_up is invoked by the Pub/Sub push subscription using OIDC tokens
#   minted by `google_service_account.invoker`.
# - scale_down + binaries-syncer are invoked by Cloud Scheduler using the same
#   invoker SA via OIDC.
###############################################################################

resource "google_cloud_run_v2_service_iam_member" "webhook_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.webhook.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "invoker_can_invoke_scale_up" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.scale_up.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.invoker.email}"
}

resource "google_cloud_run_v2_service_iam_member" "invoker_can_invoke_scale_down" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.scale_down.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.invoker.email}"
}

resource "google_cloud_run_v2_service_iam_member" "invoker_can_invoke_binaries" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.runner_binaries_syncer.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.invoker.email}"
}
