###############################################################################
# Secret Manager wiring.
#
# Secrets themselves are *expected to exist* in `var.project_id` (caller
# manages their lifecycle: rotation, replication policy, owners). This file
# only:
#   1. Looks up the secret resources to surface their resource IDs to the
#      services as env vars (already done via locals.service_env).
#   2. Grants `roles/secretmanager.secretAccessor` to each service account
#      that needs to read a particular secret. Roles are scoped per-secret
#      (not project-wide) for least privilege.
###############################################################################

data "google_secret_manager_secret" "github_app_id" {
  project   = var.project_id
  secret_id = element(reverse(split("/", var.github_app_id_secret_id)), 0)
}

data "google_secret_manager_secret" "github_app_private_key" {
  project   = var.project_id
  secret_id = element(reverse(split("/", var.github_app_private_key_secret_id)), 0)
}

data "google_secret_manager_secret" "github_webhook_secret" {
  project   = var.project_id
  secret_id = element(reverse(split("/", var.github_webhook_secret_secret_id)), 0)
}

# webhook only needs the webhook secret (signature verification).
resource "google_secret_manager_secret_iam_member" "webhook_reads_webhook_secret" {
  project   = var.project_id
  secret_id = data.google_secret_manager_secret.github_webhook_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.webhook.email}"
}

# scale-up needs everything to mint installation tokens + JIT configs.
resource "google_secret_manager_secret_iam_member" "scale_up_reads_app_id" {
  project   = var.project_id
  secret_id = data.google_secret_manager_secret.github_app_id.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.scale_up.email}"
}

resource "google_secret_manager_secret_iam_member" "scale_up_reads_app_key" {
  project   = var.project_id
  secret_id = data.google_secret_manager_secret.github_app_private_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.scale_up.email}"
}

# scale-down needs the App credentials to deregister runners on cleanup.
resource "google_secret_manager_secret_iam_member" "scale_down_reads_app_id" {
  project   = var.project_id
  secret_id = data.google_secret_manager_secret.github_app_id.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.scale_down.email}"
}

resource "google_secret_manager_secret_iam_member" "scale_down_reads_app_key" {
  project   = var.project_id
  secret_id = data.google_secret_manager_secret.github_app_private_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.scale_down.email}"
}

# binaries-syncer does not read any secrets (public actions/runner releases).
