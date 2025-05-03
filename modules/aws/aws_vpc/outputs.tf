output "vpc_id" {
  value       = aws_vpc.this["vpc"].id
  description = "The ID of the VPC"
}

output "public_subnets" {
  value       = [for subnet in aws_subnet.public : subnet.id]
  description = "The IDs of the public subnets"
}

output "private_subnets" {
  value       = [for subnet in aws_subnet.private : subnet.id]
  description = "The IDs of the private subnets"
}

output "nat_gateways" {
  value       = [for nat in aws_nat_gateway.this : nat.id]
  description = "The IDs of the NAT gateways"
}
