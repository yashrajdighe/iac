include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_organization_policy"
}

dependency "aws_accounts" {
  config_path = "../../aws_accounts/playground"

  mock_outputs = {
    account_id = "123456789012"
  }
}

dependencies {
  paths = ["../../aws_accounts/playground"]
}

inputs = {
  enabled     = "true"
  name        = "DenyAllOutsideSelectedRegions"
  description = "Deny creating resources outside selected regions"
  policy_content = {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    conditions = [
      {
        test     = "StringNotEquals"
        variable = "aws:RequestedRegion"
        values   = ["us-east-1", "ap-south-1"]
      },
    ]
  }
  policy_attachments = [dependency.aws_accounts.outputs.account_id]
}
