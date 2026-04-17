locals {
  platform = "cloudflare"

  project = "iac"
  creator = "tofu/terragrunt"
  team    = "devops"

  # Cloudflare has no native state backend in this repo; its state is persisted
  # in the AWS "common" account's S3 bucket. Keep these identities here so the
  # root terragrunt.hcl never hardcodes cross-cloud addresses.
  state_backing_platform = "aws"
  state_backing_account  = "common"
  state_bucket_region    = "us-east-1"
  state_role_arn         = "arn:aws:iam::530354880605:role/OrganizationAccountAccessRole"
}
