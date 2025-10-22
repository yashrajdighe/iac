terraform {
  source = "${local.aws_modules_root}/aws_iam_openid_connect_github_provider"
}

inputs = {
  create_github_oidc_provider = true
}
