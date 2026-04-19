terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_acm"
}

inputs = {
  domains = ["*.yashrajdighe.in"]
}
