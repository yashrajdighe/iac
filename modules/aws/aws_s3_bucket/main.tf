resource "aws_s3_bucket" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = var.name

  tags = var.tags
}

resource "aws_s3_bucket_policy" "this" {
  count = var.create_s3_bucket && local.create_bucket_policy ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = var.bucket_policy_json
}
