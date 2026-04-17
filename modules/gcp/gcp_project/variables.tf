variable "name" {
  type        = string
  description = "Name of the project"
}

variable "org_id" {
  type        = string
  default     = null
  description = "Organization ID for the project. Set exactly one of org_id or folder_id."
  validation {
    condition = (
      (var.org_id != null && var.folder_id == null) ||
      (var.org_id == null && var.folder_id != null)
    )
    error_message = "Exactly one of org_id or folder_id must be set."
  }
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
