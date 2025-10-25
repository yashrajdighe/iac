terraform {
  source = "${find_in_parent_folders("modules/aws")}/static_web_deployment"
}

inputs = {
  create_static_web_deployment   = true
  enable_cloudfront_distribution = true

  origins = [
    {
      path          = "/"
      origin_id     = "root"
      bucket_suffix = "root"
    }
  ]

  default_cache_behavior = {
    target_origin_id = "root"
  }

  default_root_object = "index.html"
}
