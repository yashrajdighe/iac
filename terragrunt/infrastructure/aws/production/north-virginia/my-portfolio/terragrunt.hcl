include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "common_inputs" {
  path = find_in_parent_folders("_env/my_portfolio.hcl")
}

inputs = {
  static_web_deployment_name = "my-portfolio-app-${include.root.locals.hierarchy.env.env}"
  github_repo_name           = "my-portfolio"
  environment_name           = include.root.locals.hierarchy.env.env
}
