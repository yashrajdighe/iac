resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "this" {
  count         = var.create_nat_gateway == "single" ? 1 : (var.create_nat_gateway == "per_az" ? length(var.public_subnets) : 0)
  allocation_id = aws_eip.this[count.index].id
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name = "${var.vpc_name}-nat-${count.index}"
  }
}

resource "aws_eip" "this" {
  count = var.create_nat_gateway == "single" ? 1 : (var.create_nat_gateway == "per_az" ? length(var.public_subnets) : 0)
  vpc   = true
}

resource "aws_route_table" "private" {
  for_each = tomap({ for idx, cidr in var.private_subnets : idx => cidr })
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.create_nat_gateway != "none" ? element(aws_nat_gateway.this.*.id, 0) : null
  }

  tags = {
    Name = "${var.vpc_name}-private-${each.key}-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_subnet" "public" {
  for_each   = tomap({ for idx, cidr in var.public_subnets : idx => cidr })
  vpc_id     = aws_vpc.this.id
  cidr_block = each.value

  tags = {
    Name = "${var.vpc_name}-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each   = tomap({ for idx, cidr in var.private_subnets : idx => cidr })
  vpc_id     = aws_vpc.this.id
  cidr_block = each.value

  tags = {
    Name = "${var.vpc_name}-private-${each.key}"
  }
}

resource "aws_subnet" "db" {
  for_each   = tomap({ for idx, cidr in var.db_subnets : idx => cidr })
  vpc_id     = aws_vpc.this.id
  cidr_block = each.value

  tags = {
    Name = "${var.vpc_name}-db-${each.key}"
  }
}

resource "aws_route_table" "db" {
  for_each = tomap({ for idx, cidr in var.db_subnets : idx => cidr })
  vpc_id   = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-db-${each.key}-rt"
  }
}

resource "aws_route_table_association" "db" {
  for_each       = aws_subnet.db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db[each.key].id
}
