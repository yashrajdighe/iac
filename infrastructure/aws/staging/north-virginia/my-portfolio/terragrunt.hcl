include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include "account" {
  path   = find_in_parent_folders("account.hcl")
  expose = true
}

include "common_inputs" {
  path = find_in_parent_folders("_env/my_portfolio.hcl")
}

dependency "kms_cmk" {
  config_path = "../../common/mumbai/kms_cmk/secrets_manager/terragrunt.hcl"

  mock_outputs = {
    kms_cmk_arn = "arn:aws:kms:us-east-1:006763131804:key/1234567890"
  }
}

dependencies {
  paths = ["../../common/mumbai/kms_cmk/secrets_manager"]
}

#locals {
# define locals here
#}

inputs = {
  static_web_deployment_name = "my-portfolio-app-${include.env.locals.env}"
  github_repo_name           = "my-portfolio"
  environment_name           = "${include.env.locals.env}"
  kms_key_arn                = dependency.kms_cmk.outputs.kms_cmk_arn
}
