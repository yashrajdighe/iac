locals {
  bucket_names = {
    for origin in var.origins : origin.bucket_suffix => "${var.static_web_deployment_name}-${origin.bucket_suffix}"
  }

  bucket_arns              = [for name in local.bucket_names : "arn:aws:s3:::${name}"]
  bucket_arns_with_objects = [for name in local.bucket_names : "arn:aws:s3:::${name}/*"]
}
