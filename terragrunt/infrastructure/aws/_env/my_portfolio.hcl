terraform {
  source = "${find_in_parent_folders("modules")}/aws/static_web_deployment"
}

locals {
  mtls_rotator = read_terragrunt_config(
    find_in_parent_folders("_env/mtls_rotator_shared.hcl", "${get_terragrunt_dir()}/terragrunt.hcl")
  )
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

  default_root_object             = "index.html"
  cloudflare_api_token_secret_arn = "arn:aws:secretsmanager:ap-south-1:530354880605:secret:/common/github/yd-devops-hub/global/CLOUDFLARE_API_TOKEN-VjcxZF"
}
