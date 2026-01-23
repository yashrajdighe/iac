data "archive_file" "lambda_layer_zip" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${path.tmp}/lambda_layer.zip"
}

resource "aws_lambda_layer_version" "this" {
  layer_name          = var.layer_name
  filename            = data.archive_file.lambda_layer_zip.output_path
  source_code_hash    = data.archive_file.lambda_layer_zip.output_base64sha256
  compatible_runtimes = var.compatible_runtimes
  description         = var.description
  license_info        = var.license_info
}
