output "project_id" {
  value       = google_project.this.id
  description = "Project ID of the project"
}

output "project_number" {
  value       = google_project.this.number
  description = "Project number of the project"
}
