resource "google_folder" "this" {
  display_name = var.name
  parent       = var.parent
}

locals {
  bootstrap_admin_roles = toset([
    "roles/owner",
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectIamAdmin",
  ])
  bootstrap_admin_bindings = {
    for pair in setproduct(var.bootstrap_admin_members, local.bootstrap_admin_roles) :
    "${pair[0]}|${pair[1]}" => {
      member = pair[0]
      role   = pair[1]
    }
  }
}

resource "google_folder_iam_member" "bootstrap_admin" {
  for_each = local.bootstrap_admin_bindings
  folder   = google_folder.this.name
  role     = each.value.role
  member   = each.value.member
}
