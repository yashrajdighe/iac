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
  mtls_rotator_role_name  = "cloudflare-origin-cert-rotator-role"
  # Must match terragrunt .../cloudflare-origin-cert-rotator/ trust_store_s3_object_key
  mtls_trust_store_object_key = "mtls/root-ca.pem"
}
