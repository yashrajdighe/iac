include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_security_group"
}

dependency "vpc" {
  config_path  = "../../vpc"
  skip_outputs = true

  mock_outputs = {
    vpc_id = "vpc-12345678"
  }
}

inputs = {
  create_security_group = false
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
      ip_protocol = "-1"
      description = "Allow all outbound traffic to anywhere"
    }
  ]
}
