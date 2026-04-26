include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_s3_bucket"
}

# S3 trust store for the Cloudflare origin mTLS root CA (devops-playground.in).
# Bucket only; cross-account bucket policy for the rotator role
# (arn:aws:iam::530354880605:role/devops-playground-in-cloudflare-origin-cert-rotator-role)
# is intentionally omitted for now and will be added in a follow-up stack.
inputs = {
  name = "devops-playground-in-production-mtls-trust-store"
}
