include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_account"
}

inputs = {
  account_name  = "playground"
  account_email = "yashraj.dighe077+aws-playground@gmail.com"
}
