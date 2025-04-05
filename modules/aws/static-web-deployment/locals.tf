locals {
  bucket_names = {
    for origin in var.origins : origin.bucket_suffix => "${var.static_web_deployment_name}-${origin.bucket_suffix}"
  }
}
