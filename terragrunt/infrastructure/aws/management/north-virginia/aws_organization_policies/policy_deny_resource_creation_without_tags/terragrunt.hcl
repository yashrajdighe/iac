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
  enabled     = "false"
  name        = "deny_all_create_without_tags"
  description = "Deny all create actions without tags"
  policy_content = {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    conditions = [
      {
        test     = "Null"
        variable = "aws:RequestTag/environment"
        values   = ["true"]
      },
      {
        test     = "Null"
        variable = "aws:RequestTag/creator"
        values   = ["true"]
      },
      {
        test     = "Null"
        variable = "aws:RequestTag/platform"
        values   = ["true"]
      },
      {
        test     = "Null"
        variable = "aws:RequestTag/project"
        values   = ["true"]
      },
      {
        test     = "Null"
        variable = "aws:RequestTag/team"
        values   = ["true"]
      },
    ]
  }
  policy_attachments = [dependency.aws_accounts.outputs.account_id]
}
