include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/static_web_deployment"
}

inputs = {
  create_static_web_deployment   = false
  static_web_deployment_name     = "my-static-website"
  enable_cloudfront_distribution = true

  origins = [
    {
      path          = "/"
      origin_id     = "primary"
      bucket_suffix = "primary"
    }
  ]

  default_cache_behavior = {
    target_origin_id = "primary"
  }

  ordered_cache_behaviors = [
    {
      path_pattern     = "/assets/*"
      target_origin_id = "primary"
    }
  ]

  default_root_object = "index.html"
  github_repo_name    = "my-portfolio"
  environment_name    = include.root.locals.hierarchy.env.env
}
