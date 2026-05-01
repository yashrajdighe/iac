include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${find_in_parent_folders("modules")}/gcp/gcp_folder"
}

inputs = {
  name   = "just-another-test-folder"
  parent = "organizations/${include.root.locals.hierarchy.org.org_id}"

  bootstrap_admin_members = ["user:yashrajdighe.dev@gmail.com"]
}
