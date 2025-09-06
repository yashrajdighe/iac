
resource "aws_security_group" "this" {
  count       = var.create_security_group ? 1 : 0
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge({
    Name = var.name
  }, var.tags)
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.create_security_group ? { for idx, rule in var.ingress_rules : idx => rule } : {}
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6         = lookup(each.value, "cidr_ipv6", null)
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  to_port           = each.value.to_port
  description       = lookup(each.value, "description", null)
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = var.create_security_group ? { for idx, rule in var.egress_rules : idx => rule } : {}
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6         = lookup(each.value, "cidr_ipv6", null)
  from_port         = lookup(each.value, "from_port", null)
  to_port           = lookup(each.value, "to_port", null)
  ip_protocol       = each.value.ip_protocol
  description       = lookup(each.value, "description", null)
}
