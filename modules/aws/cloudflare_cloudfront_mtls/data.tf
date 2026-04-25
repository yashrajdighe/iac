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
  count = var.create ? 1 : 0

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
      aws_secretsmanager_secret.root_ca[0].arn,
      aws_secretsmanager_secret.client[0].arn,
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
    resources = [for b in var.trust_store_bucket_arns : "${b}/${local.trust_store_s3_object_key}"]
  }
}
