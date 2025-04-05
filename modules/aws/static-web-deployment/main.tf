data "aws_s3_bucket" "bucket_exists" {
  for_each = var.create_static_web_deployment ? { for origin in var.origins : origin.path => origin } : {}
  bucket   = local.bucket_names[each.key]
}

resource "aws_s3_bucket" "this" {
  for_each = var.create_static_web_deployment ? { for origin in var.origins : origin.path => origin } : {}

  bucket = local.bucket_names[each.key]

  tags = var.tags

  lifecycle {
    precondition {
      condition     = !can(data.aws_s3_bucket.bucket_exists[each.key].id)
      error_message = "S3 bucket ${local.bucket_names[each.key]} already exists. Please use a different bucket name."
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  for_each = var.create_static_web_deployment ? { for origin in var.origins : origin.path => origin } : {}

  bucket = aws_s3_bucket.this[each.key].id
  policy = templatefile("${path.module}/templates/bucket_policy.tftpl", {
    bucket_name      = aws_s3_bucket.this[each.key].id
    distribution_arn = aws_cloudfront_distribution.this[0].arn
  })

  depends_on = [aws_cloudfront_distribution.this, aws_s3_bucket.this]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "this" {
  count = var.create_static_web_deployment ? 1 : 0

  depends_on = [aws_s3_bucket.this]

  dynamic "origin" {
    for_each = var.origins
    content {
      domain_name              = aws_s3_bucket.this[origin.value.path].bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.this.id
      origin_id                = origin.value.origin_id
    }
  }

  default_cache_behavior {
    target_origin_id       = var.default_cache_behavior.target_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  enabled = var.enable_cloudfront_distribution

  price_class = "PriceClass_All"

  default_root_object = var.default_root_object

  tags = var.tags
}

resource "aws_cloudfront_origin_access_control" "this" {
  count                             = var.create_static_web_deployment ? 1 : 0
  name                              = var.static_web_deployment_name
  description                       = "Policy for ${var.static_web_deployment_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
