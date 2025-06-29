resource "aws_organizations_policy" "this" {
  name        = var.name
  description = var.description
  content     = data.aws_iam_policy_document.this.json
  type        = "SERVICE_CONTROL_POLICY"
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "this" {
  count     = length(var.policy_attachments)
  policy_id = aws_organizations_policy.this.id
  target_id = var.policy_attachments[count.index]
}
