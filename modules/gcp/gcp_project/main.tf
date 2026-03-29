resource "google_project" "this" {
  name       = var.name
  project_id = var.project_id
  org_id     = var.org_id
}
