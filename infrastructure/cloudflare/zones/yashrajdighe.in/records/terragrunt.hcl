include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "zone" {
  path   = find_in_parent_folders("zone.hcl")
  expose = true
}

include "account" {
  path   = find_in_parent_folders("account.hcl")
  expose = true
}

# include "common_inputs" {
#   path = find_in_parent_folders("_env/budgets.hcl")
# }

terraform {
  source = "../../../../modules/cloudflare/cloudflare_records"
}

#dependency "<resource-name>" {
#  config_path = "../<terragrunt-file-relative-path>"

#  mock_outputs = {
#    # define mock outputs here
#  }
#}

#dependencies {
#  paths = ["../dependent-resource-terragrunt-file-relative-path"]
#}

#locals {
# define locals here
#}

inputs = {
  zone_id = "${include.zone.locals.zone_id}"
  records = {
    "test-iac" = {
      name    = "test-iac"
      type    = "A"
      content = "103.101.109.98"
      proxied = true
    }
  }
}
