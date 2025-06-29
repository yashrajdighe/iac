data "aws_iam_policy_document" "this" {
  statement {
    effect    = var.policy_content.effect
    actions   = var.policy_content.actions
    resources = var.policy_content.resources
    dynamic "principals" {
      for_each = var.policy_content.principal != null ? [var.policy_content.principal] : []
      content {
        type        = principals.value.type
        identifiers = principals.value.identifiers
      }
    }
  }
}
