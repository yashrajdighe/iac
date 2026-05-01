###############################################################################
# Service accounts: one per Cloud Run service, plus a runner SA and an
# invoker SA used by Pub/Sub push and Cloud Scheduler.
###############################################################################

resource "google_service_account" "webhook" {
  project      = var.project_id
  account_id   = local.sa_ids.webhook
  display_name = "GitHub runner webhook (Cloud Run)"
  description  = "Verifies GitHub webhook signatures and publishes workflow_job events to Pub/Sub."
}

resource "google_service_account" "scale_up" {
  project      = var.project_id
  account_id   = local.sa_ids.scale_up
  display_name = "GitHub runner scale-up (Cloud Run)"
  description  = "Pub/Sub push subscriber that creates ephemeral Compute Engine runner VMs."
}

resource "google_service_account" "scale_down" {
  project      = var.project_id
  account_id   = local.sa_ids.scale_down
  display_name = "GitHub runner scale-down (Cloud Run)"
  description  = "Scheduler-invoked sweeper that terminates idle/orphaned runner VMs and deregisters runners."
}

resource "google_service_account" "binaries" {
  project      = var.project_id
  account_id   = local.sa_ids.binaries
  display_name = "GitHub runner binaries syncer (Cloud Run)"
  description  = "Scheduler-invoked job that caches the actions/runner tarball in GCS."
}

resource "google_service_account" "runner" {
  project      = var.project_id
  account_id   = local.sa_ids.runner
  display_name = "GitHub Actions ephemeral runner VM"
  description  = "Identity used by ephemeral Compute Engine runner VMs. Scoped to log writing and runner-binaries bucket reads."
}

resource "google_service_account" "invoker" {
  project      = var.project_id
  account_id   = local.sa_ids.invoker
  display_name = "GitHub runner OIDC invoker"
  description  = "Identity used by Pub/Sub push and Cloud Scheduler to invoke control-plane Cloud Run services with an ID token."
}

###############################################################################
# Project-level IAM for runner control-plane SAs.
#
# scale-up needs to create/list/delete VMs and `actAs` the runner SA when
# launching VMs from the instance template.
# scale-down needs the same (delete VMs + list).
# webhook + binaries-syncer don't need any compute permissions.
#
# We use the predefined `roles/compute.instanceAdmin.v1` here for simplicity.
# Some permissions (e.g. compute.instances.list) operate at the project
# scope, so this is broader than strictly required. Callers operating in
# multi-tenant projects should swap in a custom role limited to
# compute.instances.{create,delete,list,get,setMetadata} +
# compute.instanceTemplates.useReadOnly + compute.subnetworks.use.
###############################################################################

resource "google_project_iam_member" "scale_up_compute" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.scale_up.email}"
}

resource "google_project_iam_member" "scale_down_compute" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.scale_down.email}"
}

# `actAs` permission so scale-up can attach the runner SA to created VMs.
resource "google_service_account_iam_member" "scale_up_acts_as_runner" {
  service_account_id = google_service_account.runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.scale_up.email}"
}

# Runner VM is allowed to read cached binaries and write logs.
resource "google_storage_bucket_iam_member" "runner_reads_binaries" {
  bucket = google_storage_bucket.runner_binaries.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_project_iam_member" "runner_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_project_iam_member" "runner_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

# Self-destruct fallback: the runner needs `compute.instances.delete` on
# itself when its idle timer expires (see scripts/runner_startup.sh.tftpl).
# We use the predefined role for simplicity. Callers wanting tighter scope
# should replace this with a custom role granting only
# compute.instances.delete + compute.instances.get on a tag-restricted
# resource set.
resource "google_project_iam_member" "runner_self_delete" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

# binaries-syncer writes the actions/runner tarball into the cache bucket.
resource "google_storage_bucket_iam_member" "binaries_writer" {
  bucket = google_storage_bucket.runner_binaries.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.binaries.email}"
}

###############################################################################
# Pub/Sub publish + queue access.
###############################################################################

resource "google_pubsub_topic_iam_member" "webhook_publishes" {
  project = var.project_id
  topic   = google_pubsub_topic.build_jobs.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.webhook.email}"
}

resource "google_pubsub_topic_iam_member" "scale_up_dlq_publish" {
  project = var.project_id
  topic   = google_pubsub_topic.build_jobs_dlq.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription_iam_member" "scale_up_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.build_jobs.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

###############################################################################
# Project metadata for the Pub/Sub service-agent ARN above.
###############################################################################

data "google_project" "this" {
  project_id = var.project_id
}
