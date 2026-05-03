include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "lambda_layer" {
  config_path = "../lambda-layer"

  mock_outputs = {
    layer_arn = "arn:aws:lambda:ap-south-1:000000000000:layer:prBotSecurityLibrary:1"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "mtls_trust_store_production" {
  config_path = "../../../production/mumbai/yashraj-dighe-mtls-trust-store"

  mock_outputs = {
    bucket_arn = "arn:aws:s3:::mock-mtls-trust-prd"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependencies {
  paths = [
    "../lambda-layer",
    "../../../production/mumbai/yashraj-dighe-mtls-trust-store",
  ]
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/cloudflare_cloudfront_mtls"
}

locals {
  mtls_rotator = read_terragrunt_config(
    find_in_parent_folders("_env/mtls_rotator_yashraj_dighe_in.hcl", "${get_terragrunt_dir()}/terragrunt.hcl")
  )
}

inputs = {
  create = true

  resource_name_prefix = local.mtls_rotator.locals.mtls_resource_name_prefix
  function_name        = local.mtls_rotator.locals.mtls_function_name

  cloudflare_zone_id = "f7550de8ebab24bd4c0a9de6c353d178"
  # Skips GET /zones/{id} (avoids Zone read on token and avoids 400s some tokens get on that GET).
  cloudflare_zone_name = "yashrajdighe.in"

  cloudflare_api_token_secret_arn = local.mtls_rotator.locals.cloudflare_api_token_secret_arn

  trust_store_bucket_arns = [
    dependency.mtls_trust_store_production.outputs.bucket_arn,
  ]

  # trust_store_s3_object_key: omit to use default; object key is derived from _env/mtls_rotator_yashraj_dighe_in.hcl (keep in sync with the trust-store buckets)
  # Layer version: use published ARN from the lambda-layer stack (do not hardcode :1; version must exist in the account).
  lambda_layer_arn = dependency.lambda_layer.outputs.layer_arn

  # ~1 month client cert rotation: new leaf on each scheduled run; validity matches the cadence.
  client_cert_validity_days      = 30
  root_ca_validity_days          = 3650
  root_ca_renew_before_days      = 120
  rotation_schedule              = "rate(30 days)"
  secret_recovery_window_in_days = 7
  log_retention_in_days          = 14
}
