include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "common_inputs" {
  path = find_in_parent_folders("_env/my_portfolio.hcl")
}

dependency "yd_acm_cert_staging" {
  config_path = "../../../../aws/staging/north-virginia/yd_acm_cert"

  mock_outputs = {
    certificate_arn = "arn:aws:acm:us-east-1:063903862285:certificate/1234567890"
  }

  mock_outputs_merge_strategy_with_state = "shallow"
}

dependencies {
  paths = ["../../../../aws/staging/north-virginia/yd_acm_cert"]
}

inputs = {
  static_web_deployment_name = "my-portfolio-app-${include.root.locals.hierarchy.env.env}"
  github_repo_name           = "my-portfolio"
  environment_name           = include.root.locals.hierarchy.env.env
  aliases                    = ["staging.yashrajdighe.in"]
  acm_certificate_arn        = dependency.yd_acm_cert_staging.outputs.arn
}
