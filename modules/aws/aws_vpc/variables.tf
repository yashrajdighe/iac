variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "db_subnets" {
  description = "List of CIDR blocks for database subnets"
  type        = list(string)
  default     = []
}

variable "create_nat_gateway" {
  description = <<EOT
Option to control NAT gateway creation:
- "single": Create a single NAT gateway.
- "per_az": Create one NAT gateway per availability zone.
- "none": Do not create any NAT gateway.
EOT
  type        = string
  default     = "none"
}
