resource "aws_cloudformation_stack_set" "this" {
  name         = var.name
  template_url = var.template_url
}
