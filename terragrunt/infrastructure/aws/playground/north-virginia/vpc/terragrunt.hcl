include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_vpc"
}

inputs = {
  create_vpc = true
  name       = "playground-vpc"
  cidr       = "10.0.0.0/16"

  azs                     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets          = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  map_public_ip_on_launch = true
}
