output "s3_buckets" {
  description = "Map of S3 buckets created for static web deployment"
  value = {
    for path, bucket in aws_s3_bucket.this : path => {
      name = bucket.id
      arn  = bucket.arn
    }
  }
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = try(aws_cloudfront_distribution.this[0].id, null)
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution (e.g. d111111abcdef8.cloudfront.net)"
  value       = try(aws_cloudfront_distribution.this[0].domain_name, null)
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the CloudFront distribution (for alias records)"
  value       = try(aws_cloudfront_distribution.this[0].hosted_zone_id, null)
}

output "origin_access_control_id" {
  description = "ID of the CloudFront Origin Access Control"
  value       = try(aws_cloudfront_origin_access_control.this[0].id, null)
}
