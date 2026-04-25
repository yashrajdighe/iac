terraform {
  source = "${find_in_parent_folders("modules")}/aws/static_web_deployment"
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

  create_mtls_trust_store = true
  mtls_rotator_account_id = "530354880605"
  # Must match the rotator Lambda IAM role name = {resource_name_prefix}{function_name}-role (see cloudflare-origin-cert-rotator terragrunt)
  mtls_rotator_role_name = "devops-playground-in-cloudflare-origin-cert-rotator-role"
  # Must match rotator: default S3 key is {normalized resource_name_prefix}root-ca.pem (e.g. devops-playground-in-root-ca.pem) unless trust_store is overridden
  mtls_trust_store_object_key = "devops-playground-in-root-ca.pem"
}
