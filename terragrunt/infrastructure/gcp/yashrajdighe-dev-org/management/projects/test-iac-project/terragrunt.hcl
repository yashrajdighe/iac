include "root" {
  path = find_in_parent_folders()
}

locals {
  org_vars = read_terragrunt_config(find_in_parent_folders("org.hcl"))

  org_id   = local.org_vars.locals.org_id
  root_dir = dirname(find_in_parent_folders())
}

terraform {
  source = "${local.root_dir}/../modules/gcp/gcp_project"
}

inputs = {
  name       = "just-another-test-project"
  project_id = "just-another-test-project"
  org_id     = local.org_id
}
