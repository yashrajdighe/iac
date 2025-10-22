terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/aws/aws_iam_openid_connect_github_provider"
}

inputs = {
  create_github_oidc_provider = true
}
