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
  cloudflare_api_token_secret_arn = local.mtls_rotator.locals.cloudflare_api_token_secret_arn

  create_mtls_trust_store     = true
  mtls_rotator_account_id     = "530354880605"
  mtls_rotator_role_name      = local.mtls_rotator.locals.mtls_rotator_role_name
  mtls_trust_store_object_key = local.mtls_rotator.locals.mtls_trust_store_object_key
  # Cross-account S3 policy fails with MalformedPolicy/Invalid principal if the rotator role does not exist in the common account yet. Bootstrap: set false, apply this stack, apply common/mumbai/cloudflare-origin-cert-rotator, set true, apply this stack again.
  mtls_trust_store_attach_rotator_policy = true
}
