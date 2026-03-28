output "name" {
  value       = google_folder.this.name
  description = "Name of the folder"
}

output "id" {
  value       = google_folder.this.id
  description = "ID of the folder"
}

output "lifecycle_state" {
  value       = google_folder.this.lifecycle_state
  description = "Lifecycle state of the folder"
}
