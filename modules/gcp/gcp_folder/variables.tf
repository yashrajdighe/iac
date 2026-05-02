variable "name" {
  type        = string
  description = "Name of the folder"
}

variable "parent" {
  type        = string
  description = "Parent of the folder. Can be an organization or a folder."
}
