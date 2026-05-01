output "project_id" {
  value       = google_project.this.project_id
  description = "Project ID string (not the projects/… resource name)."
}

output "project_number" {
  value       = google_project.this.number
  description = "Project number of the project"
}
