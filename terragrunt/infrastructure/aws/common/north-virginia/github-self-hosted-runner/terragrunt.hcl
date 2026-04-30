include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-mock0000000000000"
    private_subnets = [
      "subnet-mockaaaaaaaa",
      "subnet-mockbbbbbbbb",
      "subnet-mockcccccccc",
    ]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependencies {
  paths = ["../vpc"]
}

locals {
  runner = read_terragrunt_config(find_in_parent_folders("_env/github_self_hosted_runner_common.hcl"))
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_self_hosted_runner"
}

inputs = {
  aws_region         = include.root.locals.hierarchy.region.aws_region
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnets

  github_app_private_key_secret_arn             = local.runner.locals.github_app_private_key_secret_arn
  github_app_id_ssm_parameter_name              = local.runner.locals.github_app_id_ssm_parameter_name
  github_webhook_secret_arn                     = local.runner.locals.github_webhook_secret_arn
  github_app_installation_id_ssm_parameter_name = local.runner.locals.github_app_installation_id_ssm_parameter_name

  repository_white_list = local.runner.locals.repository_white_list
  prefix                = local.runner.locals.runner_prefix

  instance_types                 = ["c5.large", "m5.large"]
  instance_target_capacity_type  = "spot"
  enable_ephemeral_runners       = true
  scale_down_schedule_expression = "cron(*/5 * * * ? *)"
}
