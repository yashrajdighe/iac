include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${find_in_parent_folders("modules")}/cloudflare/cloudflare_records"
}

inputs = {
  zone_id = include.root.locals.hierarchy.zone.zone_id
  records = {
    "test-iac" = {
      name    = "test-iac"
      type    = "A"
      content = "103.101.109.98"
      proxied = true
    }
  }
}
