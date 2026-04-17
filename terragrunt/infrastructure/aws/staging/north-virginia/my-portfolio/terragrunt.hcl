include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "common_inputs" {
  path = find_in_parent_folders("_env/my_portfolio.hcl")
}

dependency "kms_cmk" {
  config_path = "../../../common/mumbai/kms_cmk/secrets_manager"

  mock_outputs = {
    kms_key_arn = "arn:aws:kms:us-east-1:006763131804:key/1234567890"
  }
}

dependencies {
  paths = ["../../../common/mumbai/kms_cmk/secrets_manager"]
}

inputs = {
  static_web_deployment_name = "my-portfolio-app-${include.root.locals.hierarchy.env.env}"
  github_repo_name           = "my-portfolio"
  environment_name           = include.root.locals.hierarchy.env.env
  kms_key_arn                = dependency.kms_cmk.outputs.kms_key_arn
}
