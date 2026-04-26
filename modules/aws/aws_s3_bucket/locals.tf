locals {
  create_bucket_policy           = trimspace(var.bucket_policy_json) != ""
  create_lifecycle_configuration = var.enable_retention || var.failed_multipart_upload_cleanup
}
