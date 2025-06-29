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

terraform {
  source = "../../../../../../modules/aws/aws_organization_policy"
}

inputs = {
  name        = "deny_all_create_without_tags"
  description = "Deny all EC2 actions"
  policy_content = {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    # principal is optional for SCPs, so you can omit it
    condition {
      test     = "Null"
      variable = "aws:RequestTag/environment"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/creator"
      values   = ["true"]
    }
    
    condition {
      test     = "Null"
      variable = "aws:RequestTag/platform"
      values   = ["true"]
    }
    
    condition {
      test     = "Null"
      variable = "aws:RequestTag/project"
      values   = ["true"]
    }
    
    condition {
      test     = "Null"
      variable = "aws:RequestTag/team"
      values   = ["true"]
    }
  }
}
