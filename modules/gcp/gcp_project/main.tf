check "exactly_one_of_org_or_folder" {
  assert {
    condition = (
      (var.org_id != null && var.folder_id == null) ||
      (var.org_id == null && var.folder_id != null)
    )
    error_message = "Exactly one of org_id or folder_id must be set."
  }
}

resource "google_project" "this" {
  name       = var.name
  project_id = var.project_id
  org_id     = var.org_id
  folder_id  = var.folder_id
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

resource "google_project_iam_member" "bootstrap_admin" {
  for_each = local.bootstrap_admin_bindings
  project  = google_project.this.project_id
  role     = each.value.role
  member   = each.value.member
}
