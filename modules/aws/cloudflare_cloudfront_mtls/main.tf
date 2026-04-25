check "root_ca_renew_window" {
  assert {
    condition     = var.root_ca_renew_before_days >= 1 && var.root_ca_renew_before_days < var.root_ca_validity_days
    error_message = "root_ca_renew_before_days must be >= 1 and < root_ca_validity_days so auto-rotation triggers before a full lifetime elapses."
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/${local.lambda_function_name}.zip"
}

resource "aws_secretsmanager_secret" "root_ca" {
  name                    = "${local.secret_name_stem}/root-ca"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = var.tags
}

resource "aws_secretsmanager_secret" "client" {
  name                    = "${local.secret_name_stem}/client-cert"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_iam_role" "this" {
  name               = "${local.lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.lambda_function_name}-execution"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_execution.json
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "this" {
  function_name = local.lambda_function_name
  role          = aws_iam_role.this.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.14"
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  layers = [var.lambda_layer_arn]

  environment {
    variables = {
      CLOUDFLARE_ZONE_ID              = var.cloudflare_zone_id
      CLOUDFLARE_API_TOKEN_SECRET_ARN = var.cloudflare_api_token_secret_arn
      ROOT_CA_SECRET_ARN              = aws_secretsmanager_secret.root_ca.arn
      CLIENT_CERT_SECRET_ARN          = aws_secretsmanager_secret.client.arn
      TRUST_STORE_BUCKET_NAMES        = join(",", [for b in var.trust_store_bucket_arns : replace(b, "arn:aws:s3:::", "")])
      TRUST_STORE_S3_OBJECT_KEY       = local.trust_store_s3_object_key
      ROOT_CA_VALIDITY_DAYS           = tostring(var.root_ca_validity_days)
      ROOT_CA_RENEW_BEFORE_DAYS       = tostring(var.root_ca_renew_before_days)
      CLIENT_CERT_VALIDITY_DAYS       = tostring(var.client_cert_validity_days)
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.basic,
    aws_cloudwatch_log_group.this,
  ]
}

resource "aws_cloudwatch_event_rule" "rotation" {
  name                = "${local.lambda_function_name}-rotation"
  description         = "Triggers Cloudflare origin client certificate rotation"
  schedule_expression = var.rotation_schedule
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "rotation" {
  rule      = aws_cloudwatch_event_rule.rotation.name
  target_id = "lambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotation.arn
}
