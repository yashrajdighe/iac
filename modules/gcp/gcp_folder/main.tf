resource "google_folder" "this" {
  display_name = var.name
  parent       = var.parent
}
