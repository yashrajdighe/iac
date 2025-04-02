resource "aws_organizations_organization" "org" {
  aws_service_access_principals = var.aws_service_access_principals
  feature_set                   = var.feature_set
}

import {
  id = "o-xxxxxxxxxx" # Replace with your actual AWS Organization ID
  to = aws_organizations_organization.org
}
