include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_vpc"
}

inputs = {
  create_vpc = true
  name       = "common-us-east-1"
  cidr       = "10.64.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.64.0.0/24", "10.64.1.0/24", "10.64.2.0/24"]
  private_subnets = ["10.64.10.0/24", "10.64.11.0/24", "10.64.12.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}
