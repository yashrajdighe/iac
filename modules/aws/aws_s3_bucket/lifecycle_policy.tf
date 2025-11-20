resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_policy" {
  # create lifecycle configuration only if the bucket itself is being created
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  # retention rule (dynamic so it can be toggled with var.enable_retention)
  dynamic "rule" {
    for_each = var.enable_retention ? [1] : []
    content {
      id     = "retention-policy-rule"
      status = "Enabled"

      expiration {
        days = var.retention_days
      }
    }
  }

  # cleanup rule for failed multipart uploads (toggle with var.failed_multipart_upload_cleanup)
  dynamic "rule" {
    for_each = var.failed_multipart_upload_cleanup ? [1] : []
    content {
      id     = "failed-multipart-upload-cleanup-rule"
      status = "Enabled"

      abort_incomplete_multipart_upload {
        days_after_initiation = 1
      }
    }
  }
}
