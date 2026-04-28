# Zone-agnostic shared config for the Cloudflare origin mTLS rotator and trust-store stacks.
# Per-zone values (resource name prefix and everything derived from it) live in
# sibling files: _env/mtls_rotator_<zone>.hcl, e.g. _env/mtls_rotator_devops_playground_in.hcl.

locals {
  # Cloudflare API token used by the rotator. If you scope tokens per-zone,
  # move this into the per-zone file instead of keeping it here.
  cloudflare_api_token_secret_arn = "arn:aws:secretsmanager:ap-south-1:530354880605:secret:/common/github/yashrajdighe/iac/CLOUDFLARE_API_TOKEN-eefAwH"

  # AWS account that hosts the rotator Lambda (and currently the trust-store buckets).
  # Could become get_aws_account_id() if you only ever deploy from this account.
  mtls_rotator_account_id = "530354880605"

  # Base lambda function name; the per-zone prefix is prepended to this.
  mtls_function_name = "cloudflare-origin-cert-rotator"
}
