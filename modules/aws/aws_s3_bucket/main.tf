resource "aws_s3_bucket" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = var.name

  tags = var.tags
}
