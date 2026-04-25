locals {
  # e.g. "acme" or "acme-" -> "acme-"; empty -> no prefix
  resource_prefix = (
    var.resource_name_prefix == ""
    ? ""
    : "${trimsuffix(trimspace(var.resource_name_prefix), "-")}-"
  )

  lambda_function_name = "${local.resource_prefix}${var.function_name}"
  secret_name_stem     = "${local.resource_prefix}${var.secret_name_prefix}"

  # Default object key: same normalized prefix as other resources, then "root-ca.pem" (e.g. acme-root-ca.pem; empty prefix => root-ca.pem)
  trust_store_s3_object_key = coalesce(
    var.trust_store_s3_object_key,
    "${local.resource_prefix}root-ca.pem"
  )
}
