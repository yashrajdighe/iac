locals {
  platform_vars       = read_terragrunt_config(find_in_parent_folders("platform.hcl"))
  account_vars        = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars         = try(read_terragrunt_config(find_in_parent_folders("region.hcl")), { locals = { aws_region = "" } })
  env_vars            = try(read_terragrunt_config(find_in_parent_folders("env.hcl")), { locals = { env = "" } })
  common_account_vars = read_terragrunt_config("${get_repo_root()}/infrastructure/aws/common/account.hcl")

  platform     = local.platform_vars.locals.platform
  account_name = local.account_vars.locals.account_name
  iam_role     = try(local.account_vars.locals.iam_role, "")
  aws_region   = local.region_vars.locals.aws_region
  env          = local.env_vars.locals.env

  # For non-AWS platforms, state is stored in the common AWS account.
  state_account_name = local.platform == "aws" ? local.account_name : local.common_account_vars.locals.account_name
  state_role_arn     = local.platform == "aws" ? local.iam_role : local.common_account_vars.locals.iam_role

  bucket_region = "us-east-1" # always be in north virginia for state bucket
  project       = "iac"
  creator       = "tofu/terragrunt"
  team          = "devops"
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

remote_state {
  backend = "s3"
  config = merge(
    {
      encrypt        = true
      bucket         = "${local.state_account_name}-${local.platform}-${local.project}-tf-states"
      key            = "${path_relative_to_include()}/terraform.tfstate"
      region         = local.bucket_region
      dynamodb_table = "${local.state_account_name}-${local.platform}-${local.project}-tf-locks"
    },
    local.state_role_arn != "" ? {
      assume_role = {
        role_arn = local.state_role_arn
      }
    } : {}
  )
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
