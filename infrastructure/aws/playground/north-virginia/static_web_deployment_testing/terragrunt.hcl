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

terraform {
  source = "../../../../../modules/aws/static_web_deployment"
}

#dependency "<resource-name>" {
#  config_path = "../<terragrunt-file-relative-path>"

#  mock_outputs = {
#    # define mock outputs here
#  }
#}

#dependencies {
#  paths = ["../dependent-resource-terragrunt-file-relative-path"]
#}

#locals {
# define locals here
#}

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
}
