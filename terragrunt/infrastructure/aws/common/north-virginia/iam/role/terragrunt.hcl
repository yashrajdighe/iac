include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role"
}

dependency "policy" {
  config_path = "../policy"

  mock_outputs = {
    arn = "arn:aws:iam::123456789012:policy/polic-name"
  }
}

dependencies {
  paths = ["../policy"]
}

inputs = {
  name               = "common-yashrajdighe-git-repo-backup"
  enable_github_oidc = true
  oidc_wildcard_subjects = [
    "repo:yashrajdighe/backup-git-repos:ref:refs/heads/main"
  ]
  policies = {
    write-github-s3-backup = dependency.policy.outputs.arn
  }
}
