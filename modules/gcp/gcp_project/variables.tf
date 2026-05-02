variable "name" {
  type        = string
  description = "Name of the project"
}

variable "org_id" {
  type        = string
  default     = null
  description = "Organization ID for the project. Set exactly one of org_id or folder_id."
}

variable "folder_id" {
  type        = string
  default     = null
  description = "Folder ID for the project. Set exactly one of org_id or folder_id."
}

variable "project_id" {
  type        = string
  description = "Project ID of the project"
}
