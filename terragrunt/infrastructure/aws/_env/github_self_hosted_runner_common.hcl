locals {
  # Same region as the runner stack (us-east-1). Update secret ARNs if AWS assigned new suffixes after migration.

  github_app_private_key_secret_arn = "arn:aws:secretsmanager:us-east-1:530354880605:secret:/common/github/yashrajdighe/iac/self-hosted-runner-rHuk0Y"

  github_app_id_ssm_parameter_name = "arn:aws:ssm:us-east-1:530354880605:parameter/common/github/yashrajdighe/iac/self-hosted-runner/app-id"

  github_app_installation_id_ssm_parameter_name = "arn:aws:ssm:us-east-1:530354880605:parameter/common/github/yashrajdighe/iac/self-hosted-runner/app-installation-id"

  github_webhook_secret_arn = "arn:aws:secretsmanager:us-east-1:530354880605:secret:/common/github/yashrajdighe/iac/self-hosted-runner/webhook-secret-ovpztH"

  repository_white_list = ["yashrajdighe/iac"]

  runner_prefix = "github-actions-common"
}
