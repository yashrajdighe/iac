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

variable "bootstrap_admin_members" {
  type        = set(string)
  default     = []
  description = "IAM members (e.g. user:person@example.com) granted each role in bootstrap_project_iam_roles on this project."
}

variable "bootstrap_project_iam_roles" {
  type = set(string)
  default = [
    "roles/editor",
    "roles/resourcemanager.projectIamAdmin",
  ]
  description = "Project-scoped roles for bootstrap_admin_members. Do not use folder-only roles (e.g. roles/resourcemanager.folderAdmin). roles/owner may be rejected for external users unless the org allows it (ORG_MUST_INVITE_EXTERNAL_OWNERS)."
}
