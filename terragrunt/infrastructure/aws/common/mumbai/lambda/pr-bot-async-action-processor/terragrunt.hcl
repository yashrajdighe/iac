include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_lambda"
}

inputs = {
  function_name = "prBotAsyncActionProcessor"
  handler       = "index.handler"
  runtime       = "python3.14"
  source_path   = "./code"
  tags = {
    app_name = "GreenLight"
  }
  layers      = ["arn:aws:lambda:ap-south-1:530354880605:layer:prBotSecurityLibrary:1"]
  description = "Background worker that handles the actual GitHub authentication, approval, merging, and Slack UI updates."
}
