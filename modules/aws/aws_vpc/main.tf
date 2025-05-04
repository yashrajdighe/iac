resource "aws_vpc" "this" {
  for_each   = var.create_vpc ? { "vpc" : var.vpc_cidr_block } : {}
  cidr_block = each.value

  tags = var.tags
}

resource "aws_internet_gateway" "this" {
  for_each = var.create_vpc ? { "igw" : aws_vpc.this["vpc"].id } : {}
  vpc_id   = each.value

  tags = var.tags
}

resource "aws_route_table" "public" {
  for_each = var.create_vpc ? { "public" : aws_vpc.this["vpc"].id } : {}
  vpc_id   = each.value

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this["igw"].id
  }

  tags = var.tags
}

resource "aws_route_table_association" "public" {
  for_each       = var.create_vpc ? aws_subnet.public : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public["public"].id
}

resource "aws_nat_gateway" "this" {
  for_each      = var.create_vpc && var.create_nat_gateway != "none" ? tomap({ for idx, subnet in aws_subnet.public : idx => subnet }) : {}
  allocation_id = aws_eip.this[each.key].id
  subnet_id     = each.value.id

  tags = var.tags
}

resource "aws_eip" "this" {
  for_each = var.create_vpc && var.create_nat_gateway != "none" ? tomap({ for idx, subnet in aws_subnet.public : idx => subnet }) : {}
  vpc      = true
}

resource "aws_route_table" "private" {
  for_each = var.create_vpc ? tomap({ for idx, cidr in var.private_subnets : idx => cidr }) : {}
  vpc_id   = aws_vpc.this["vpc"].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.create_nat_gateway != "none" ? aws_nat_gateway.this[0].id : null
  }

  tags = var.tags
}

resource "aws_route_table_association" "private" {
  for_each       = var.create_vpc ? tomap({ for idx, subnet in aws_subnet.private : idx => subnet }) : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_subnet" "public" {
  for_each   = var.create_vpc ? tomap({ for idx, cidr in var.public_subnets : idx => cidr }) : {}
  vpc_id     = aws_vpc.this["vpc"].id
  cidr_block = each.value

  tags = var.tags
}

resource "aws_subnet" "private" {
  for_each   = var.create_vpc ? tomap({ for idx, cidr in var.private_subnets : idx => cidr }) : {}
  vpc_id     = aws_vpc.this["vpc"].id
  cidr_block = each.value

  tags = var.tags
}

resource "aws_subnet" "db" {
  for_each   = var.create_vpc ? tomap({ for idx, cidr in var.db_subnets : idx => cidr }) : {}
  vpc_id     = aws_vpc.this["vpc"].id
  cidr_block = each.value

  tags = var.tags
}

resource "aws_route_table" "db" {
  for_each = var.create_vpc ? tomap({ for idx, cidr in var.db_subnets : idx => cidr }) : {}
  vpc_id   = aws_vpc.this["vpc"].id

  tags = var.tags
}

resource "aws_route_table_association" "db" {
  for_each       = var.create_vpc ? tomap({ for idx, subnet in aws_subnet.db : idx => subnet }) : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db[each.key].id
}
