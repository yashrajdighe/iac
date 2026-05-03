include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "common_inputs" {
  path = find_in_parent_folders("_env/my_portfolio.hcl")
}

dependency "yd_acm_cert_development" {
  config_path = "../../../../aws/development/north-virginia/yd_acm_cert"

  mock_outputs = {
    certificate_arn = "arn:aws:acm:us-east-1:006763131804:certificate/1234567890"
  }

  mock_outputs_merge_strategy_with_state = "shallow"
}

dependencies {
  paths = ["../../../../aws/development/north-virginia/yd_acm_cert"]
}

inputs = {
  static_web_deployment_name = "my-portfolio-app-${include.root.locals.hierarchy.env.env}"
  github_repo_name           = "my-portfolio"
  environment_name           = include.root.locals.hierarchy.env.env
  aliases                    = ["dev.yashrajdighe.in"]
  acm_certificate_arn        = dependency.yd_acm_cert_development.outputs.arn
}
