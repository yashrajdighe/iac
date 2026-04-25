# Shared naming and secrets for the Cloudflare origin mTLS rotator and static_web_deployment.
# - Resource names must match cloudflare_cloudfront_mtls: resource_prefix, lambda function name, trust store object key.
# - CLOUDFLARE_API_TOKEN: one secret for rotator and static web (getSecretValue; default AWS-managed Secrets Manager key).

locals {
  cloudflare_api_token_secret_arn = "arn:aws:secretsmanager:ap-south-1:530354880605:secret:/common/github/yashrajdighe/iac/CLOUDFLARE_API_TOKEN-eefAwH"

  mtls_resource_name_prefix = "devops-playground-in"
  mtls_function_name        = "cloudflare-origin-cert-rotator"

  # Mirrors module: trimsuffix(name, "-") + "-" (empty prefix => "")
  mtls_resource_prefix = (
    local.mtls_resource_name_prefix == ""
    ? ""
    : "${trimsuffix(trimspace(local.mtls_resource_name_prefix), "-")}-"
  )

  mtls_lambda_function_name   = "${local.mtls_resource_prefix}${local.mtls_function_name}"
  mtls_rotator_role_name      = "${local.mtls_lambda_function_name}-role"
  mtls_trust_store_object_key = "${local.mtls_resource_prefix}root-ca.pem"
}
