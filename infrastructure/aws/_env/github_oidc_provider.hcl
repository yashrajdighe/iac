terraform {
  source = "${find_in_parent_folders("modules/aws")}/aws_iam_openid_connect_github_provider"
}

inputs = {
  create_github_oidc_provider = true
}
