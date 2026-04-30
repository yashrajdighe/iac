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

dependency "mtls_trust_store_development" {
  config_path = "../../../development/mumbai/devops-playground-mtls-trust-store"

  mock_outputs = {
    bucket_arn = "arn:aws:s3:::mock-mtls-trust-dev"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "mtls_trust_store_staging" {
  config_path = "../../../staging/mumbai/devops-playground-mtls-trust-store"

  mock_outputs = {
    bucket_arn = "arn:aws:s3:::mock-mtls-trust-stg"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "mtls_trust_store_production" {
  config_path = "../../../production/mumbai/devops-playground-mtls-trust-store"

  mock_outputs = {
    bucket_arn = "arn:aws:s3:::mock-mtls-trust-prd"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependencies {
  paths = [
    "../lambda-layer",
    "../../../development/mumbai/devops-playground-mtls-trust-store",
    "../../../staging/mumbai/devops-playground-mtls-trust-store",
    "../../../production/mumbai/devops-playground-mtls-trust-store",
  ]
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/cloudflare_cloudfront_mtls"
}

locals {
  mtls_rotator = read_terragrunt_config(
    find_in_parent_folders("_env/mtls_rotator_devops_playground_in.hcl", "${get_terragrunt_dir()}/terragrunt.hcl")
  )
}

inputs = {
  create = true
  # Secrets already exist in ap-south-1; adopt into state so apply does not call CreateSecret again.
  import_existing_secretsmanager_secrets = true

  resource_name_prefix = local.mtls_rotator.locals.mtls_resource_name_prefix
  function_name        = local.mtls_rotator.locals.mtls_function_name

  cloudflare_zone_id = "35382e17c94bbbeedef73e026144798f"
  # Skips GET /zones/{id} (avoids Zone read on token and avoids 400s some tokens get on that GET).
  cloudflare_zone_name = "devops-playground.in"

  cloudflare_api_token_secret_arn = local.mtls_rotator.locals.cloudflare_api_token_secret_arn

  trust_store_bucket_arns = [
    dependency.mtls_trust_store_development.outputs.bucket_arn,
    dependency.mtls_trust_store_staging.outputs.bucket_arn,
    dependency.mtls_trust_store_production.outputs.bucket_arn,
  ]

  # trust_store_s3_object_key: omit to use default; object key is derived from _env/mtls_rotator_devops_playground_in.hcl (keep in sync with the trust-store buckets)
  # Layer version: use published ARN from the lambda-layer stack (do not hardcode :1; version must exist in the account).
  lambda_layer_arn = dependency.lambda_layer.outputs.layer_arn

  # Short-lived values for testing (revert to e.g. 30 / 3650 / 120 for production)
  client_cert_validity_days = 2
  root_ca_validity_days     = 4
  # Must be < root_ca_validity_days; cannot be 4 when root is 4. Set to 2 to match client cert window.
  root_ca_renew_before_days = 2
  # With client_cert_validity_days=2, the Lambda must run more often than every 2 days or the client cert expires. Use daily (or e.g. rate(12 hours)) for this test profile; use rate(28 days) with prod day counts.
  rotation_schedule              = "rate(1 day)"
  secret_recovery_window_in_days = 7
  log_retention_in_days          = 14
}
