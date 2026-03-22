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
  source = "../../../../../../../modules/aws/aws_lambda"
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
  function_name = "prBotGithubWebhookHandler"
  handler       = "index.handler"
  runtime       = "python3.14"
  source_path   = "./code"
  tags = {
    app_name = "GreenLight"
  }
  layers      = ["arn:aws:lambda:ap-south-1:530354880605:layer:prBotSecurityLibrary:1"]
  description = "Listens for new PR events and posts the interactive Approve notification block to Slack."
}
