locals {
  create_lifecycle_configuration = var.enable_retention || var.failed_multipart_upload_cleanup
}
