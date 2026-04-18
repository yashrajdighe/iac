include "root" {
  path = find_in_parent_folders()
}

include "common_inputs" {
  path = find_in_parent_folders("_env/github_oidc_provider.hcl")
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_cloudformation_stackset"
}

inputs = {
  name                    = "GitHub-OIDC-Provider"
  template_url            = "https://my-initial-cf-stack-templates.s3.us-east-1.amazonaws.com/identity-provider-github.json"
  organizational_unit_ids = ["r-kfvz"]
  regions                 = ["us-east-1"]
}
