output "s3_buckets" {
  description = "Map of S3 buckets created for static web deployment"
  value = {
    for path, bucket in aws_s3_bucket.this : path => {
      name = bucket.id
      arn  = bucket.arn
    }
  }
}

output "cloudfront_distributions" {
  description = "Map of CloudFront distributions created for static web deployment"
  value = {
    for path, distribution in aws_cloudfront_distribution.this : path => {
      id             = distribution.id
      domain_name    = distribution.domain_name
      hosted_zone_id = distribution.hosted_zone_id
    }
  }
}

output "origin_access_control_id" {
  description = "ID of the CloudFront Origin Access Control"
  value       = aws_cloudfront_origin_access_control.this[0].id
}
