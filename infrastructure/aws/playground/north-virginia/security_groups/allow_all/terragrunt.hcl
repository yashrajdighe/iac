include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include "account" {
  path   = find_in_parent_folders("account.hcl")
  expose = true
}

terraform {
  source = "../../../../../../modules/aws/aws_security_group"
}

dependency "vpc" {
  config_path                             = "../../vpc"
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]

  mock_outputs_merge_strategy_with_state = "deep_map_only"

  mock_outputs = {
    # define mock outputs here
    vpc_id = "vpc-12345678"
  }
}

dependencies {
  paths = ["../../vpc"]
}

inputs = {
  # define module inputs here
  create_security_group = true
  name                  = "allow-all-traffic"
  description           = "This security group allows all inbound traffic."
  vpc_id                = dependency.vpc.outputs.vpc_id

  ingress_rules = [
    {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
      ip_protocol = "-1"
      description = "Allow all inbound traffic from anywhere"
    }
  ]
  egress_rules = [
    {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
      ip_protocol = "-1"
      description = "Allow all outbound traffic to anywhere"
    }
  ]
}
