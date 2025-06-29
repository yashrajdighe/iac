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
  source = "../../../../../modules/aws/aws_organization_policy"
}

inputs = {
  name        = "deny-ec2"
  description = "Deny all EC2 actions"
  policy_content = {
    effect    = "Deny"
    actions   = ["ec2:*"]
    resources = ["*"]
    # principal is optional for SCPs, so you can omit it
  }
}
