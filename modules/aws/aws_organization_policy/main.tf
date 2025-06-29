resource "aws_organizations_policy" "this" {
  count       = var.enabled ? 1 : 0
  name        = var.name
  description = var.description
  content     = data.aws_iam_policy_document.this.json
  type        = "SERVICE_CONTROL_POLICY"
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "this" {
  count     = var.enabled ? length(var.policy_attachments) : 0
  policy_id = aws_organizations_policy.this[0].id
  target_id = var.policy_attachments[count.index]
}
