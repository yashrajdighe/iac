resource "aws_vpc" "this" {
  count      = var.create_vpc ? 1 : 0
  cidr_block = var.vpc_cidr_block

  tags = var.tags
}

resource "aws_internet_gateway" "this" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = var.tags
}

resource "aws_route_table" "public" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = var.tags
}

resource "aws_route_table_association" "public" {
  count          = var.create_vpc ? length(aws_subnet.public) : 0
  for_each       = var.create_vpc ? aws_subnet.public : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_nat_gateway" "this" {
  count         = var.create_vpc && var.create_nat_gateway == "single" ? 1 : (var.create_nat_gateway == "per_az" ? length(var.public_subnets) : 0)
  allocation_id = aws_eip.this[count.index].id
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = var.tags
}

resource "aws_eip" "this" {
  count = var.create_vpc && var.create_nat_gateway == "single" ? 1 : (var.create_nat_gateway == "per_az" ? length(var.public_subnets) : 0)
  vpc   = true
}

resource "aws_route_table" "private" {
  count    = var.create_vpc ? length(var.private_subnets) : 0
  for_each = tomap({ for idx, cidr in var.private_subnets : idx => cidr })
  vpc_id   = aws_vpc.this[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.create_nat_gateway != "none" ? element(aws_nat_gateway.this.*.id, 0) : null
  }

  tags = var.tags
}

resource "aws_route_table_association" "private" {
  count          = var.create_vpc ? length(aws_subnet.private) : 0
  for_each       = var.create_vpc ? aws_subnet.private : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_subnet" "public" {
  count      = var.create_vpc ? length(var.public_subnets) : 0
  for_each   = tomap({ for idx, cidr in var.public_subnets : idx => cidr })
  vpc_id     = aws_vpc.this[0].id
  cidr_block = each.value

  tags = var.tags
}

resource "aws_subnet" "private" {
  count      = var.create_vpc ? length(var.private_subnets) : 0
  for_each   = tomap({ for idx, cidr in var.private_subnets : idx => cidr })
  vpc_id     = aws_vpc.this[0].id
  cidr_block = each.value

  tags = var.tags
}

resource "aws_subnet" "db" {
  count      = var.create_vpc ? length(var.db_subnets) : 0
  for_each   = tomap({ for idx, cidr in var.db_subnets : idx => cidr })
  vpc_id     = aws_vpc.this[0].id
  cidr_block = each.value

  tags = var.tags
}

resource "aws_route_table" "db" {
  count    = var.create_vpc ? length(var.db_subnets) : 0
  for_each = tomap({ for idx, cidr in var.db_subnets : idx => cidr })
  vpc_id   = aws_vpc.this[0].id

  tags = var.tags
}

resource "aws_route_table_association" "db" {
  count          = var.create_vpc ? length(aws_subnet.db) : 0
  for_each       = var.create_vpc ? aws_subnet.db : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db[each.key].id
}
