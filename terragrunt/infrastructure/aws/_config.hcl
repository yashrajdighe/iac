locals {
  platform = "aws"

  project = "iac"
  creator = "tofu/terragrunt"
  team    = "devops"

  state_bucket_region   = "us-east-1"
  common_account_name   = "common"
  common_state_role_arn = "arn:aws:iam::530354880605:role/OrganizationAccountAccessRole"
}
