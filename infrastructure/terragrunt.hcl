locals {
  account_vars  = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars   = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  iam_role      = local.account_vars.locals.iam_role
  bucket_region = "us-east-1" # always be in north virginia for state bucket
  aws_region    = local.region_vars.locals.aws_region
  account_name  = local.account_vars.locals.account_name
  env           = local.env_vars.locals.env
  platform      = "aws" # optional
  project       = "iac" # optional
  creator       = "tofu/terragrunt"
  team          = "devops"

  aws_modules_root = read_terragrunt_config(find_in_parent_folders("modules_path.hcl")).locals.aws_modules_root
}

generate "provider" {
  disable   = local.iam_role == "" ? true : false
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
        provider "aws" {
            region = "${local.aws_region}"
            default_tags {
                tags = {
                    platform = "${local.platform}"
                    project = "${local.project}"
                    creator = "${local.creator}"
                    team = "${local.team}"
                    environment = "${local.env}"
                }
            }
            assume_role {
              role_arn = "${local.iam_role}"
            }
        }
    EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "${local.account_name}-${local.platform}-${local.project}-tf-states"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.bucket_region}"
    dynamodb_table = "${local.account_name}-${local.platform}-${local.project}-tf-locks"
    assume_role = {
      role_arn = "${local.iam_role}"
    }
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
