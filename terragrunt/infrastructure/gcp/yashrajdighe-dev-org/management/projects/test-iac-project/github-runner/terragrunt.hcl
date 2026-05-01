###############################################################################
# Reference Terragrunt consumer for the github-runner-gcp module.
#
# Demonstrates the canonical wiring:
#   - Sourced from `modules/gcp/github-runner-gcp` via the same shared
#     `find_in_parent_folders("modules")` indirection used elsewhere in the
#     repo.
#   - Depends on the parent project (test-iac-project) for `project_id`.
#   - Caller-managed Secret Manager secrets are supplied by full resource
#     IDs; the parent project must create them before this stack runs.
#
# This stack is intentionally NOT applied automatically. After bootstrapping:
#   1. Create the three Secret Manager secrets in the project (App ID,
#      private key PEM, webhook secret) and add a version with real values.
#   2. Build and push the four control-plane images (services/Makefile).
#   3. Pin their digests in modules/gcp/github-runner-gcp/main.tf or pass
#      them via the *_image inputs below.
#   4. Run `terragrunt apply`.
###############################################################################

# `find_in_parent_folders()` alone would resolve to ../terragrunt.hcl (the
# test-iac-project stack), which itself includes root — Terragrunt allows only
# one include level. Anchor on the repo-root _shared template, then include
# terragrunt/terragrunt.hcl next to it.
include "root" {
  path = "${dirname(find_in_parent_folders("_shared/providers/gcp.tftpl"))}/terragrunt.hcl"
}

terraform {
  source = "${find_in_parent_folders("modules")}/gcp/github-runner-gcp"
}

dependency "project" {
  config_path = ".."

  mock_outputs = {
    project_id = "just-another-test-project-123"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependencies {
  paths = [".."]
}

locals {
  region = "asia-south1"
}

inputs = {
  project_id = dependency.project.outputs.project_id
  region     = local.region
  zones      = ["${local.region}-a", "${local.region}-b"]

  network    = "projects/${dependency.project.outputs.project_id}/global/networks/default"
  subnetwork = "projects/${dependency.project.outputs.project_id}/regions/${local.region}/subnetworks/default"

  github_app_id_secret_id          = "projects/${dependency.project.outputs.project_id}/secrets/github-app-id"
  github_app_private_key_secret_id = "projects/${dependency.project.outputs.project_id}/secrets/github-app-private-key"
  github_webhook_secret_secret_id  = "projects/${dependency.project.outputs.project_id}/secrets/github-webhook-secret"

  prefix              = "iac-runner"
  machine_types       = ["c4-standard-4"]
  runner_architecture = "x64"

  runner_extra_labels   = ["iac-gcp"]
  runners_maximum_count = 2

  labels = {
    app_name = "selh-hosted-runner"
  }
}
