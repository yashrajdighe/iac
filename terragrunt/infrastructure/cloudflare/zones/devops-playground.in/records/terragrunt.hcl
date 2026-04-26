include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${find_in_parent_folders("modules")}/cloudflare/cloudflare_records"
}

inputs = {
  zone_id = include.root.locals.hierarchy.zone.zone_id
  tg_path = include.root.locals.tg_path
  records = {
    "test-iac" = {
      name    = "test-iac"
      type    = "A"
      content = "103.101.109.99"
      proxied = true
    }
  }
}
