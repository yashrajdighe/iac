include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_organization"
}

inputs = {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
  ]
  feature_set = "ALL"
}
