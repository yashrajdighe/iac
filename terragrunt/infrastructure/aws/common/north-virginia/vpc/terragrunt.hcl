include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_vpc"
}

inputs = {
  create_vpc = true
  name       = "github-actions-common-vpc"
  # /28 is the smallest subnet AWS allows; ~11 assignable IPs after reservations (/29 and smaller are not supported).
  cidr            = "10.64.255.0/28"
  azs             = ["us-east-1a"]
  public_subnets  = ["10.64.255.0/28"]
  private_subnets = []

  enable_nat_gateway = false

  map_public_ip_on_launch = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
}
