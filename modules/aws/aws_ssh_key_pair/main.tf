resource "aws_key_pair" "this" {
  count      = var.create_ssh_key_pair ? 1 : 0
  key_name   = var.key_name
  public_key = var.public_key
  tags       = var.tags
}
