include "root" {
  path = find_in_parent_folders()
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
  layers      = ["arn:aws:lambda:ap-south-1:530354880605:layer:prBotSecurityLibrary:1"]
  description = "Listens for new PR events and posts the interactive Approve notification block to Slack."
}
