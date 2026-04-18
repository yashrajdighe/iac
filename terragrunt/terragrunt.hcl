# ─────────────────────────────────────────────────────────────────────────────
# Root Terragrunt configuration.
#
# This file is intentionally free of cloud-specific identities and constants.
# All such values live in per-platform files so adding a new cloud only
# requires:
#   1. infrastructure/<cloud>/_config.hcl   (platform = "<cloud>" + identities)
#   2. _shared/providers/<cloud>.tftpl      (provider block template)
#   3. A per-platform var map in `provider_vars_map` below (empty if none) and
#      an entry in the backend selector ternary (s3 / gcs / ...).
# ─────────────────────────────────────────────────────────────────────────────

locals {
  # ── Per-platform configuration (replaces the old platform.hcl) ───────────
  cfg_vars = read_terragrunt_config(find_in_parent_folders("_config.hcl"))
  cfg      = local.cfg_vars.locals
  platform = local.cfg.platform

  # ── Optional hierarchy files ─────────────────────────────────────────────
  # Each cloud uses a subset; try() keeps the root usable from any depth.
  account_vars = try(read_terragrunt_config(find_in_parent_folders("account.hcl")), { locals = {} })
  env_vars     = try(read_terragrunt_config(find_in_parent_folders("env.hcl")), { locals = {} })
  region_vars  = try(read_terragrunt_config(find_in_parent_folders("region.hcl")), { locals = {} })
  org_vars     = try(read_terragrunt_config(find_in_parent_folders("org.hcl")), { locals = {} })
  project_vars = try(read_terragrunt_config(find_in_parent_folders("project.hcl")), { locals = {} })
  zone_vars    = try(read_terragrunt_config(find_in_parent_folders("zone.hcl")), { locals = {} })

  # Exposed to children via include.root.locals.hierarchy so child terragrunt
  # files only need a single `include "root"` block.
  hierarchy = {
    cfg     = local.cfg
    account = local.account_vars.locals
    env     = local.env_vars.locals
    region  = local.region_vars.locals
    org     = local.org_vars.locals
    project = local.project_vars.locals
    zone    = local.zone_vars.locals
  }

  # ── Backend selector (S3 for AWS/Cloudflare, GCS for GCP) ────────────────
  # State paths below are bit-identical to the previous root config so no
  # state migration / terraform init -reconfigure is required.
  state_account_name = (
    local.platform == "aws" ? lookup(local.account_vars.locals, "account_name", "") :
    local.platform == "cloudflare" ? lookup(local.cfg, "state_backing_account", "") :
    ""
  )
  state_role_arn = (
    local.platform == "aws" ? lookup(local.account_vars.locals, "iam_role", "") :
    local.platform == "cloudflare" ? lookup(local.cfg, "state_role_arn", "") :
    ""
  )
  gcp_state_project = coalesce(
    lookup(local.project_vars.locals, "project_name", ""),
    lookup(local.org_vars.locals, "state_project_name", ""),
    "unset",
  )

  # Each backend config is pre-serialised to a string so the ternary in
  # remote_state compares two strings (consistent types) rather than two
  # differently-shaped objects (which HCL rejects). jsondecode() converts the
  # winner back to a dynamic value accepted by remote_state.config.
  s3_backend_json = jsonencode({
    encrypt        = true
    bucket         = "${local.state_account_name}-${local.platform}-${local.cfg.project}-tf-states"
    key            = "${trimprefix(path_relative_to_include(), "infrastructure/")}/terraform.tfstate"
    region         = lookup(local.cfg, "state_bucket_region", "us-east-1")
    dynamodb_table = "${local.state_account_name}-${local.platform}-${local.cfg.project}-tf-locks"
    assume_role    = { role_arn = local.state_role_arn }
  })

  gcs_backend_json = jsonencode({
    bucket   = "${local.gcp_state_project}-gcp-${local.cfg.project}-tf-states"
    prefix   = trimprefix(path_relative_to_include(), "infrastructure/gcp/")
    project  = lookup(local.project_vars.locals, "project_id", "")
    location = lookup(local.project_vars.locals, "project_region", "")
  })

  backend_json = local.platform == "gcp" ? local.gcs_backend_json : local.s3_backend_json

  # ── Provider generation ──────────────────────────────────────────────────
  # Templates live under _shared/providers/<platform>.tftpl and are rendered
  # here (the only place with access to both cfg and the hierarchy).

  # Path of the resource within the terragrunt/ directory, e.g.
  #   "infrastructure/gcp/<org>/<folder>/projects/<project>".
  # Injected into each provider as a default tag/label so every provisioned
  # resource can be traced back to its Terragrunt configuration.
  tg_path = path_relative_to_include()

  # GCP label values must match [\p{Ll}\p{Lo}\p{N}_-]{0,63}; slashes are not
  # allowed, so we substitute "/" with "__" for the GCP variant only.
  tg_path_gcp_label = replace(lower(local.tg_path), "/", "__")

  provider_vars_map = {
    aws = {
      platform    = local.cfg.platform
      project     = local.cfg.project
      creator     = local.cfg.creator
      team        = local.cfg.team
      environment = lookup(local.env_vars.locals, "env", "")
      aws_region  = lookup(local.region_vars.locals, "aws_region", "")
      iam_role    = lookup(local.account_vars.locals, "iam_role", "")
      tg_path     = local.tg_path
    }
    gcp = {
      tg_path = local.tg_path_gcp_label
    }
    # Cloudflare provider has no default_tags equivalent, so nothing to inject.
    cloudflare = {}
  }

  provider_template = find_in_parent_folders("_shared/providers/${local.platform}.tftpl")
  provider_contents = templatefile(local.provider_template, lookup(local.provider_vars_map, local.platform, {}))
}

# ── Provider ────────────────────────────────────────────────────────────────

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.provider_contents
}

# ── Remote state ────────────────────────────────────────────────────────────

remote_state {
  backend = local.platform == "gcp" ? "gcs" : "s3"

  config = jsondecode(local.backend_json)

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
