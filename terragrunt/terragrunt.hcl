locals {
  platform_vars = read_terragrunt_config(find_in_parent_folders("platform.hcl"))
  account_vars  = try(read_terragrunt_config(find_in_parent_folders("account.hcl")), { locals = { account_name = "", iam_role = "" } })
  region_vars   = try(read_terragrunt_config(find_in_parent_folders("region.hcl")), { locals = { aws_region = "" } })
  env_vars      = try(read_terragrunt_config(find_in_parent_folders("env.hcl")), { locals = { env = "" } })

  platform     = local.platform_vars.locals.platform
  account_name = local.account_vars.locals.account_name
  iam_role     = try(local.account_vars.locals.iam_role, "")
  aws_region   = local.region_vars.locals.aws_region
  env          = local.env_vars.locals.env

  # Common AWS account — state backend for all non-AWS, non-GCP platforms.
  common_account_name   = "common"
  common_state_role_arn = "arn:aws:iam::530354880605:role/OrganizationAccountAccessRole"

  # For non-AWS platforms (except GCP), state is stored in the common AWS account.
  state_account_name = local.platform == "aws" ? local.account_name : local.common_account_name
  state_role_arn     = local.platform == "aws" ? local.iam_role : (local.platform == "gcp" ? "" : local.common_state_role_arn)

  # GCP remote state — always stored in the management project bucket.
  gcp_management_project_id = "project-c0cea0c3-cf00-4dc8-b6d"
  gcp_state_bucket          = "management-gcp-iac-tf-states"
  gcp_state_location        = "US"

  bucket_region = "us-east-1" # always be in north virginia for state bucket
  project       = "iac"
  creator       = "tofu/terragrunt"
  team          = "devops"

  state_path = trimprefix(path_relative_to_include(), "infrastructure/")

  s3_state_config = merge(
    {
      encrypt        = true
      bucket         = "${local.state_account_name}-${local.platform}-${local.project}-tf-states"
      key            = "${local.state_path}/terraform.tfstate"
      region         = local.bucket_region
      dynamodb_table = "${local.state_account_name}-${local.platform}-${local.project}-tf-locks"
    },
    local.state_role_arn != "" ? {
      assume_role = {
        role_arn = local.state_role_arn
      }
    } : {}
  )

  gcs_state_config = {
    project  = local.gcp_management_project_id
    bucket   = local.gcp_state_bucket
    prefix   = local.state_path
    location = local.gcp_state_location
  }
}

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

generate "cloudflare_provider" {
  disable   = local.platform != "cloudflare" ? true : false
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

provider "google" {}
EOF
}

remote_state {
  backend = local.platform == "gcp" ? "gcs" : "s3"
  config  = local.platform == "gcp" ? local.gcs_state_config : local.s3_state_config
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
