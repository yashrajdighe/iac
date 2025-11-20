resource "aws_s3_bucket_lifecycle_configuration" "retention_policy" {
  count  = var.enable_retention && var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "retention-policy-rule"
    status = "Enabled"

    expiration {
      days = var.retention_days
    }
  }
}
