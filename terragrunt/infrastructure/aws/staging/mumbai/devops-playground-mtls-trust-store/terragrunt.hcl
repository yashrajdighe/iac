include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_s3_bucket"
}

locals {
  mtls_rotator = read_terragrunt_config(
    find_in_parent_folders("_env/mtls_rotator_devops_playground_in.hcl", "${get_terragrunt_dir()}/terragrunt.hcl")
  )

  bucket_name = "devops-playground-in-staging-mtls-trust-store"
}

# S3 trust store for the Cloudflare origin mTLS root CA (devops-playground.in).
inputs = {
  name = local.bucket_name

  bucket_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudflareOriginCertRotator"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.mtls_rotator.locals.mtls_rotator_account_id}:role/${local.mtls_rotator.locals.mtls_rotator_role_name}"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = "arn:aws:s3:::${local.bucket_name}/${local.mtls_rotator.locals.mtls_trust_store_object_key}"
      }
    ]
  })
}
