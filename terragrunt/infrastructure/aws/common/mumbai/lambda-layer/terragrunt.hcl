include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_lambda_layer"
}

inputs = {
  layer_name          = "prBotSecurityLibrary"
  source_path         = "./prBotSecurityLibrary"
  compatible_runtimes = ["python3.14"]
  description         = "Shared layer containing HMAC verification logic and compiled dependencies (requests, pyjwt, cryptography)."
}
