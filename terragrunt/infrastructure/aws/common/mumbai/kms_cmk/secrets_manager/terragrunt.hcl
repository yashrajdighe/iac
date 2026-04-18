include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_kms_cmk"
}

inputs = {
  description = "AWS CMK for managing secrets"
  alias_name  = "alias/${include.root.locals.hierarchy.env.env}-secrets-manager-cmk"
  allowed_use_role_arn = [
    "arn:aws:iam::006763131804:role/my-portfolio-app-development-deployment-role",
    "arn:aws:iam::063903862285:role/my-portfolio-app-staging-deployment-role",
    "arn:aws:iam::403245569160:role/my-portfolio-app-production-deployment-role",
  ]
}
