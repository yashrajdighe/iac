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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy"
  # source = "terraform-aws-modules/iam/aws//modules/iam-policy"
}

#dependency "<resource-name>" {
#  config_path = "../<terragrunt-file-relative-path>"

#  mock_outputs = {
#    # define mock outputs here
#  }
#}

#dependencies {
#  paths = ["../dependent-resource-terragrunt-file-relative-path"]
#}

#locals {
# define locals here
#}

inputs = {
  name        = "common-yashrajdighe-git-repo-backup"
  description = "This policy allows write access to S3 bucket for GitHub repo backup to Github Repo"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "s3:get*",
            "s3:put*",
            "s3:delete*"
          ],
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::common-yashrajdighe-git-repo-backup/*"
        },
        {
          "Action": [
            "s3:ListBucket",
          ],
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::common-yashrajdighe-git-repo-backup"
        }
      ]
    }
  EOF
}
