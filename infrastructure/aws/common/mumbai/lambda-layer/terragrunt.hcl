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
  source = "../../../../../modules/aws/aws_lambda_layer"
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
  layer_name          = "prBotSecurityLibrary"
  source_path         = "./prBotSecurityLibrary"
  compatible_runtimes = ["python3.14"]
  description         = "Shared layer containing HMAC verification logic and compiled dependencies (requests, pyjwt, cryptography)."
}
