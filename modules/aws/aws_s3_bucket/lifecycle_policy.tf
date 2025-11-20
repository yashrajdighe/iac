resource "aws_s3_bucket_lifecycle_configuration" "retention_policy" {
  count  = var.enable_retention && var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "retention-policy-rule"
    status = "Enabled"

    expiration {
      days = var.retention_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "failed_multipart_upload_cleanup" {
  count  = var.failed_multipart_upload_cleanup && var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "failed-multipart-upload-cleanup-rule"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
