resource "aws_cloudformation_stack_set" "this" {
  name             = var.name
  template_url     = var.template_url
  permission_model = "SERVICE_MANAGED"
  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  administration_role_arn = "arn:aws:iam::183631350996:role/aws-service-role/stacksets.cloudformation.amazonaws.com/AWSServiceRoleForCloudFormationStackSetsOrgAdmin" # managed by AWS
}

resource "aws_cloudformation_stack_instances" "this" {
  deployment_targets {
    organizational_unit_ids = var.organizational_unit_ids
  }

  regions        = var.regions
  stack_set_name = aws_cloudformation_stack_set.this.name
}
