output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the VPC"
}

output "public_subnets" {
  value       = aws_subnet.public[*].id
  description = "The IDs of the public subnets"
}

output "private_subnets" {
  value       = aws_subnet.private[*].id
  description = "The IDs of the private subnets"
}

output "nat_gateways" {
  value       = aws_nat_gateway.this[*].id
  description = "The IDs of the NAT gateways"
}
