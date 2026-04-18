include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_s3_bucket"
}

inputs = {
  create_s3_bucket                = true
  name                            = "common-yashrajdighe-git-repo-backup"
  enable_retention                = true
  retention_days                  = 30
  failed_multipart_upload_cleanup = true
}
