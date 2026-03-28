include "root" {
  path = find_in_parent_folders()
}

locals {
  org_vars = read_terragrunt_config(find_in_parent_folders("org.hcl"))

  org_id = local.org_vars.locals.org_id
}

terraform {
  source = "${get_repo_root()}/modules/gcp/gcp_folder"
}

inputs = {
  name   = "iac"
  parent = "organizations/${local.org_id}"
}
