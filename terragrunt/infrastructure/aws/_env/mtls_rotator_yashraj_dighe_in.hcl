# Per-zone config for the Cloudflare origin mTLS rotator on yashrajdighe.in.
# Re-exports the zone-agnostic values from _env/mtls_rotator_common.hcl so that
# consumers only need to read this one file.
#
# To onboard another zone, copy this file to _env/mtls_rotator_<zone>.hcl and
# change `mtls_resource_name_prefix` (and the API token ARN if tokens are per-zone).

locals {
  common = read_terragrunt_config(
    find_in_parent_folders("_env/mtls_rotator_common.hcl", "${get_terragrunt_dir()}/terragrunt.hcl")
  )

  # Pass-throughs from the common file (kept here so consumers do a single read).
  cloudflare_api_token_secret_arn = local.common.locals.cloudflare_api_token_secret_arn
  mtls_rotator_account_id         = local.common.locals.mtls_rotator_account_id
  mtls_function_name              = local.common.locals.mtls_function_name

  # Zone-specific: prefix used for the Lambda function, IAM role, and trust-store object key.
  mtls_resource_name_prefix = "yashraj-dighe-in"

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
