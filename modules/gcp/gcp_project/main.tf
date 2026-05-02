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
