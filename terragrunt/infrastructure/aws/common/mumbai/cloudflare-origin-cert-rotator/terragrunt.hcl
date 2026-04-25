include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "my_portfolio_development" {
  config_path = "../../../development/north-virginia/my-portfolio"

  mock_outputs = {
    mtls_trust_store_bucket_arn = "arn:aws:s3:::mock-mtls-trust-dev"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "my_portfolio_staging" {
  config_path = "../../../staging/north-virginia/my-portfolio"

  mock_outputs = {
    mtls_trust_store_bucket_arn = "arn:aws:s3:::mock-mtls-trust-stg"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "my_portfolio_production" {
  config_path = "../../../production/north-virginia/my-portfolio"

  mock_outputs = {
    mtls_trust_store_bucket_arn = "arn:aws:s3:::mock-mtls-trust-prd"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependencies {
  paths = [
    "../../../development/north-virginia/my-portfolio",
    "../../../staging/north-virginia/my-portfolio",
    "../../../production/north-virginia/my-portfolio",
  ]
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/cloudflare_cloudfront_mtls"
}

locals {
  mtls_rotator = read_terragrunt_config(
    find_in_parent_folders("_env/mtls_rotator_shared.hcl", "${get_terragrunt_dir()}/terragrunt.hcl")
  )
}

inputs = {
  resource_name_prefix = local.mtls_rotator.locals.mtls_resource_name_prefix
  function_name        = local.mtls_rotator.locals.mtls_function_name

  cloudflare_zone_id = "35382e17c94bbbeedef73e026144798f" # devops-playground.in

  cloudflare_api_token_secret_arn = local.mtls_rotator.locals.cloudflare_api_token_secret_arn

  trust_store_bucket_arns = [
    dependency.my_portfolio_development.outputs.mtls_trust_store_bucket_arn,
    dependency.my_portfolio_staging.outputs.mtls_trust_store_bucket_arn,
    dependency.my_portfolio_production.outputs.mtls_trust_store_bucket_arn,
  ]

  # trust_store_s3_object_key: omit to use default; object key is derived from _env/mtls_rotator_shared.hcl (keep in sync with my-portfolio)
  lambda_layer_name    = "prBotSecurityLibrary"
  lambda_layer_version = 1

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
