variable "name" {
  type        = string
  description = "Name of the folder"
}

variable "parent" {
  type        = string
  description = "Parent of the folder. Can be an organization or a folder."
}

variable "bootstrap_admin_members" {
  type        = set(string)
  default     = []
  description = "IAM members (e.g. user:person@example.com) granted roles/owner, roles/resourcemanager.folderAdmin, and roles/resourcemanager.projectIamAdmin on this folder."
}
