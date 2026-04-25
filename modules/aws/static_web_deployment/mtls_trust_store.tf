resource "aws_s3_bucket" "mtls_trust_store" {
  count  = var.create_mtls_trust_store ? 1 : 0
  bucket = local.mtls_trust_store_name
  tags   = var.tags

  lifecycle {
    precondition {
      condition     = !var.create_mtls_trust_store || (var.mtls_rotator_account_id != "" && var.mtls_rotator_role_name != "")
      error_message = "When create_mtls_trust_store is true, set mtls_rotator_account_id and mtls_rotator_role_name to the rotator Lambda role in the common account."
    }
  }
}

data "aws_iam_policy_document" "mtls_trust_store" {
  count = var.create_mtls_trust_store ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.mtls_rotator_account_id}:role/${var.mtls_rotator_role_name}"]
    }
    resources = ["${aws_s3_bucket.mtls_trust_store[0].arn}/${var.mtls_trust_store_object_key}"]
  }
}

resource "aws_s3_bucket_public_access_block" "mtls_trust_store" {
  count  = var.create_mtls_trust_store ? 1 : 0
  bucket = aws_s3_bucket.mtls_trust_store[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "mtls_trust_store" {
  count  = var.create_mtls_trust_store ? 1 : 0
  bucket = aws_s3_bucket.mtls_trust_store[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mtls_trust_store" {
  count  = var.create_mtls_trust_store ? 1 : 0
  bucket = aws_s3_bucket.mtls_trust_store[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "mtls_trust_store" {
  count  = var.create_mtls_trust_store ? 1 : 0
  bucket = aws_s3_bucket.mtls_trust_store[0].id
  policy = data.aws_iam_policy_document.mtls_trust_store[0].json

  depends_on = [aws_s3_bucket_public_access_block.mtls_trust_store]
}
