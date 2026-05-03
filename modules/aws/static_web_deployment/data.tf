data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    sid    = "GithubOidcAuth"
    effect = "Allow"

    actions = [
      "sts:TagSession",
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org_name}/${var.github_repo_name}:environment:${var.environment_name}"]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "token.actions.githubusercontent.com:iss"
      values   = ["https://token.actions.githubusercontent.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:get*",
      "s3:put*",
      "s3:delete*"
    ]
    resources = concat(local.bucket_arns, local.bucket_arns_with_objects)
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = local.bucket_arns
  }
}

data "aws_iam_policy_document" "ssm_parameter_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [var.cloudflare_api_token_ssm_parameter_arn]
  }
}
