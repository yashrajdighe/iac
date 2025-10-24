resource "aws_cloudformation_stack_set" "this" {
  name             = var.name
  template_url     = var.template_url
  permission_model = "SERVICE_MANAGED"
}

resource "aws_cloudformation_stack_instances" "this" {
  deployment_targets {
    organizational_unit_ids = var.organizational_unit_ids
  }

  regions        = var.regions
  stack_set_name = aws_cloudformation_stack_set.this.name
}
