include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_vpc"
}

inputs = {
  create_vpc      = false
  vpc_name        = "dev-vpc"
  vpc_cidr_block  = "10.0.0.0/16"
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  db_subnets      = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}
