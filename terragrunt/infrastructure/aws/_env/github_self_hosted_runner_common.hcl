locals {
  # Credentials in ap-south-1; runner compute in us-east-1. Role needs secretsmanager:GetSecretValue + ssm:GetParameter (Mumbai).

  # Lambda zip downloads (Terragrunt before_hook) — must match modules/aws/aws_self_hosted_runner module version patch line.
  github_runner_release_tag = "v6.10.1"

  github_app_private_key_secret_arn = "arn:aws:secretsmanager:ap-south-1:530354880605:secret:/common/github/yashrajdighe/iac/self-hosted-runner-GDRF3S"

  github_app_id_ssm_parameter_name = "arn:aws:ssm:ap-south-1:530354880605:parameter/common/github/yashrajdighe/iac/self-hosted-runner/app-id"

  github_app_installation_id_ssm_parameter_name = "arn:aws:ssm:ap-south-1:530354880605:parameter/common/github/yashrajdighe/iac/self-hosted-runner/app-installation-id"

  github_webhook_secret_arn = "arn:aws:secretsmanager:ap-south-1:530354880605:secret:/common/github/yashrajdighe/iac/self-hosted-runner/webhook-secret-FjET8x"

  repository_white_list = ["yashrajdighe/iac"]

  runner_prefix = "github-actions-common"
}
