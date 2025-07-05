include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include "account" {
  path   = find_in_parent_folders("account.hcl")
  expose = true
}

dependency "aws_accounts" {
  config_path = "../../aws_accounts/playground"

  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  # mock_outputs_allowed_terraform_commands = ["validate"]
  mock_outputs = {
    account_id = "123456789012"
  }
}

dependencies {
  paths = ["../../aws_accounts/playground"]
}

terraform {
  source = "../../../../../../modules/aws/aws_organization_policy"
}

inputs = {
  enabled     = "true"
  name        = "DenyAllOutsideSelectedRegions"
  description = "Deny creating resources outside selected regions"
  policy_content = {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    # principal is optional for SCPs, so you can omit it
    conditions = [
      {
        test     = "StringNotEquals"
        variable = "aws:RequestedRegion"
        values   = ["us-east-1", "ap-south-1"]
      }
    ]
  }
  policy_attachments = [dependency.aws_accounts.outputs.account_id]
}
