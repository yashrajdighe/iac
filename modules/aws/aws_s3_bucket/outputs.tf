output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = try(aws_s3_bucket.this[0].id, null)
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = try(aws_s3_bucket.this[0].arn, null)
}
