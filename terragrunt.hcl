locals {
  account_vars  = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars   = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  iam_role      = local.account_vars.locals.iam_role
  bucket_region = "us-east-1" # to be dynamic
  aws_region    = local.region_vars.locals.aws_region
  env           = local.env_vars.locals.env
  platform      = "aws" # optional
  #host          = "<host>" # optional
  project = "iac" # optional
  creator = "terraform/terragrunt"
  team    = "devops"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
        provider "aws" {
            region = "${local.aws_region}"
            default_tags {
                tags = {
                    platform = "${local.platform}"
                    #host = "${local.host}"
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
        terraform {
            required_providers {
                aws = {
                    source  = "hashicorp/aws"
                    version = ">= 4.43.0"
                }
            }
            required_version = ">= 1.3.1"
        }
    EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "${local.platform}-${local.host}-${local.project}-tf-states"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.bucket_region}"
    dynamodb_table = "${local.platform}-${local.host}-${local.project}-tf-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}