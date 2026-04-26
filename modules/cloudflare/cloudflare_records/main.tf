locals {
  default_comment = "Created by iac. TG_PATH: ${var.tg_path}"
}

resource "cloudflare_dns_record" "this" {
  for_each = var.records

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  ttl     = each.value.proxied ? 1 : each.value.ttl
  proxied = each.value.proxied
  comment = each.value.comment != "" ? each.value.comment : local.default_comment
  tags    = each.value.tags

  priority = each.value.priority
}
