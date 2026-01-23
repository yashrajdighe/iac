data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${path.module}/${var.function_name}.zip"
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.create_role ? 1 : 0

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  count = var.create_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = var.create_role ? 1 : 0

  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_lambda_basic_execution_role" {
  count = var.create_role ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "additional" {
  count = var.create_role ? length(var.additional_policy_arns) : 0

  role       = aws_iam_role.this[0].name
  policy_arn = var.additional_policy_arns[count.index]
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  handler       = var.handler
  runtime       = var.runtime
  role          = var.create_role ? aws_iam_role.this[0].arn : var.role_arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  layers      = var.layers
  memory_size = var.memory_size
  timeout     = var.timeout
  description = var.description

  environment {
    variables = var.environment_variables
  }

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.aws_lambda_basic_execution_role,
    aws_iam_role_policy_attachment.additional,
  ]
}
