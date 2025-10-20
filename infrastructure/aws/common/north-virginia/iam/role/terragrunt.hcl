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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role"
  # source = "terraform-aws-modules/iam/aws//modules/iam-role"
}

dependency "policy" {
  config_path = "../policy"

  mock_outputs = {
    # define mock outputs here
    arn = "arn:aws:iam::123456789012:policy/polic-name"
  }
}

dependencies {
  paths = ["../policy"]
}

#locals {
# define locals here
#}

inputs = {
  enable_github_oidc = true
  oidc_wildcard_subjects = [
    "repo:yashrajdighe/backup-git-repos:*" # should be updated later
  ]
  policies = {
    write-github-s3-backup = dependency.policy.outputs.arn
  }
}
