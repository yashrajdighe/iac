locals {
  platform_vars = read_terragrunt_config(find_in_parent_folders("platform.hcl"))
  account_vars  = try(read_terragrunt_config(find_in_parent_folders("account.hcl")), { locals = { account_name = "", iam_role = "" } })
  region_vars   = try(read_terragrunt_config(find_in_parent_folders("region.hcl")), { locals = { aws_region = "" } })
  env_vars      = try(read_terragrunt_config(find_in_parent_folders("env.hcl")), { locals = { env = "" } })
  # Per-org GCP config — mirrors account.hcl for AWS.
  gcp_org_vars = try(read_terragrunt_config(find_in_parent_folders("org.hcl")), { locals = { service_account = "", state_project_name = "" } })
  # Per-project GCP config — mirrors per-account account.hcl for AWS.
  gcp_project_vars = try(read_terragrunt_config(find_in_parent_folders("project.hcl")), { locals = { project_name = "" } })

  platform     = local.platform_vars.locals.platform
  account_name = local.account_vars.locals.account_name
  iam_role     = try(local.account_vars.locals.iam_role, "")
  aws_region   = local.region_vars.locals.aws_region
  env          = local.env_vars.locals.env

  project = "iac"
  creator = "tofu/terragrunt"
  team    = "devops"

  # ── S3 state (AWS / Cloudflare) ──────────────────────────────────────────
  common_account_name   = "common"
  common_state_role_arn = "arn:aws:iam::530354880605:role/OrganizationAccountAccessRole"

  state_account_name = local.platform == "aws" ? local.account_name : local.common_account_name
  state_role_arn     = local.platform == "aws" ? local.iam_role : local.common_state_role_arn
  bucket_region      = "us-east-1" # always north virginia for state buckets

  # ── GCS state (GCP) ──────────────────────────────────────────────────────
  # CI/CD base identity — used by the GCS backend (level 1, set by the WIF auth step).
  gcp_wif_provider = "projects/850812025847/locations/global/workloadIdentityPools/yashrajdighe-iac-readonly/providers/read-access"
  gcp_ci_sa        = "yashrajdighe-iac-readonly@project-c0cea0c3-cf00-4dc8-b6d.iam.gserviceaccount.com"
  # State project resolution (mirrors state_account_name for AWS):
  #   1. Use project_name from the closest project.hcl (resources scoped to a GCP project).
  #   2. Fall back to org.hcl → state_project_name for org-level resources (e.g. folders)
  #      that have no project.hcl in their path.
  gcp_state_project = local.gcp_project_vars.locals.project_name != "" ? local.gcp_project_vars.locals.project_name : local.gcp_org_vars.locals.state_project_name
  gcp_state_bucket  = "${local.gcp_state_project}-gcp-${local.project}-tf-states"
  # Per-org provider identity — impersonated by the provider (level 2, mirrors iam_role per AWS account).
  gcp_provider_sa = local.gcp_org_vars.locals.service_account
}

# ── AWS ──────────────────────────────────────────────────────────────────────

generate "aws_provider" {
  disable   = local.platform != "aws"
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  default_tags {
    tags = {
      platform    = "${local.platform}"
      project     = "${local.project}"
      creator     = "${local.creator}"
      team        = "${local.team}"
      environment = "${local.env}"
    }
  }
  assume_role {
    role_arn = "${local.iam_role}"
  }
}
EOF
}

generate "aws_backend" {
  disable   = local.platform != "aws"
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "${local.state_account_name}-${local.platform}-${local.project}-tf-states"
    key            = "${trimprefix(path_relative_to_include(), "infrastructure/")}/terraform.tfstate"
    region         = "${local.bucket_region}"
    dynamodb_table = "${local.state_account_name}-${local.platform}-${local.project}-tf-locks"
    assume_role    = { role_arn = "${local.state_role_arn}" }
  }
}
EOF
}

# ── Cloudflare ────────────────────────────────────────────────────────────────

generate "cloudflare_provider" {
  disable   = local.platform != "cloudflare"
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.18.0"
    }
  }
}

provider "cloudflare" {}
EOF
}

generate "cloudflare_backend" {
  disable   = local.platform != "cloudflare"
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "${local.state_account_name}-${local.platform}-${local.project}-tf-states"
    key            = "${trimprefix(path_relative_to_include(), "infrastructure/")}/terraform.tfstate"
    region         = "${local.bucket_region}"
    dynamodb_table = "${local.state_account_name}-${local.platform}-${local.project}-tf-locks"
    assume_role    = { role_arn = "${local.state_role_arn}" }
  }
}
EOF
}

# ── GCP ───────────────────────────────────────────────────────────────────────

generate "gcp_provider" {
  disable   = local.platform != "gcp"
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  impersonate_service_account = "${local.gcp_provider_sa}"
}
EOF
}

generate "gcp_backend" {
  disable   = local.platform != "gcp"
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "gcs" {
    bucket = "${local.gcp_state_bucket}"
    prefix = "${trimprefix(path_relative_to_include(), "infrastructure/gcp/")}"
  }
}
EOF
}
