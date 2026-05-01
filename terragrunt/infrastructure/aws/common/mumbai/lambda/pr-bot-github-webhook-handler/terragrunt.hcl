include "root" {
  path = find_in_parent_folders()
}

dependency "lambda_layer" {
  config_path = "../../lambda-layer"

  mock_outputs = {
    layer_arn = "arn:aws:lambda:ap-south-1:000000000000:layer:prBotSecurityLibrary:1"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependencies {
  paths = [
    "../../lambda-layer"
  ]
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_lambda"
}

inputs = {
  function_name = "prBotGithubWebhookHandler"
  handler       = "index.handler"
  runtime       = "python3.14"
  source_path   = "./code"
  tags = {
    app_name = "GreenLight"
  }
  layers      = [dependency.lambda_layer.outputs.layer_arn]
  description = "Listens for new PR events and posts the interactive Approve notification block to Slack."
}
