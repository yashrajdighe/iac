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

inputs = {
  function_name = "cloudflare-origin-cert-rotator"

  cloudflare_zone_id = "35382e17c94bbbeedef73e026144798f" # devops-playground.in

  # Update if you rotate or rename the common-account secret.
  cloudflare_api_token_secret_arn = "arn:aws:secretsmanager:ap-south-1:530354880605:secret:/common/github/yashrajdighe/iac/CLOUDFLARE_API_TOKEN-eefAwH"

  trust_store_bucket_arns = [
    dependency.my_portfolio_development.outputs.mtls_trust_store_bucket_arn,
    dependency.my_portfolio_staging.outputs.mtls_trust_store_bucket_arn,
    dependency.my_portfolio_production.outputs.mtls_trust_store_bucket_arn,
  ]

  # S3 key for the public root CA in each trust-store bucket; must match _env/my_portfolio.hcl mtls_trust_store_object_key
  trust_store_s3_object_key = "devops-playground-in/root-ca.pem"

  lambda_layer_arn = "arn:aws:lambda:ap-south-1:530354880605:layer:prBotSecurityLibrary:1"

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
