data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_execution" {
  # Log delivery: AWSLambdaBasicExecutionRole (attached) covers CreateLogGroup/Stream, PutLogEvents.
  statement {
    sid    = "OwnSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      aws_secretsmanager_secret.root_ca.arn,
      aws_secretsmanager_secret.client.arn,
    ]
  }

  statement {
    sid    = "CloudflareToken"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [var.cloudflare_api_token_secret_arn]
  }

  statement {
    sid    = "TrustStoreObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]
    resources = [for b in var.trust_store_bucket_arns : "${b}/${var.trust_store_s3_object_key}"]
  }
}
