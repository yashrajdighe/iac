resource "aws_organizations_account" "account" {
  name              = var.account_name
  email             = var.account_email
  role_name         = var.organization_role_name
  close_on_deletion = true

  lifecycle {
    prevent_destroy = true
  }
}
