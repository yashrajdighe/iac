resource "aws_organizations_policy" "this" {
  name        = var.name
  description = var.description
  content     = data.aws_iam_policy_document.this.json
  type        = "SERVICE_CONTROL_POLICY"
  tags        = var.tags
}
