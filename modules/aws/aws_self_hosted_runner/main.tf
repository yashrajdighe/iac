data "aws_secretsmanager_secret_version" "github_app_key" {
  provider  = aws.mumbai
  secret_id = var.github_app_private_key_secret_arn
}

data "aws_ssm_parameter" "github_app_id" {
  provider = aws.mumbai
  name     = var.github_app_id_ssm_parameter_name
}

data "aws_secretsmanager_secret_version" "github_webhook_secret" {
  provider  = aws.mumbai
  secret_id = var.github_webhook_secret_arn
}

data "aws_ssm_parameter" "github_app_installation_id" {
  count    = var.github_app_installation_id_ssm_parameter_name != null ? 1 : 0
  provider = aws.mumbai
  name     = var.github_app_installation_id_ssm_parameter_name
}

locals {
  upstream_runner_semver = "6.10.1"
  # Artifacts directory name matches the upstream release tag (vX.Y.Z), separate from the registry version (X.Y.Z).
  upstream_runner_lambda_artifacts_directory = "${path.module}/lambda_artifacts/v${local.upstream_runner_semver}"

  create_service_linked_role_spot = coalesce(
    var.create_service_linked_role_spot,
    var.instance_target_capacity_type == "spot",
  )
}

module "github_runners" {
  source  = "github-aws-runners/github-runner/aws"
  version = local.upstream_runner_semver

  aws_region = var.aws_region
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Vendored from https://github.com/github-aws-runners/terraform-aws-github-runner/releases (registry module has no zips).
  webhook_lambda_zip                = "${local.upstream_runner_lambda_artifacts_directory}/webhook.zip"
  runners_lambda_zip                = "${local.upstream_runner_lambda_artifacts_directory}/runners.zip"
  runner_binaries_syncer_lambda_zip = "${local.upstream_runner_lambda_artifacts_directory}/runner-binaries-syncer.zip"

  github_app = {
    key_base64     = data.aws_secretsmanager_secret_version.github_app_key.secret_string
    webhook_secret = data.aws_secretsmanager_secret_version.github_webhook_secret.secret_string
    id_ssm = {
      arn  = data.aws_ssm_parameter.github_app_id.arn
      name = data.aws_ssm_parameter.github_app_id.name
    }
  }

  instance_types                  = var.instance_types
  instance_target_capacity_type   = var.instance_target_capacity_type
  enable_ephemeral_runners        = var.enable_ephemeral_runners
  repository_white_list           = var.repository_white_list
  scale_down_schedule_expression  = var.scale_down_schedule_expression
  prefix                          = var.prefix
  create_service_linked_role_spot = local.create_service_linked_role_spot
  tags                            = var.tags
}
