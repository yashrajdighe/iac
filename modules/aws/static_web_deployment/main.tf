resource "aws_s3_bucket" "this" {
  for_each = var.create_static_web_deployment ? { for origin in var.origins : origin.bucket_suffix => origin } : {}

  bucket = local.bucket_names[each.key]
  tags   = var.tags
}

resource "aws_s3_bucket_policy" "this" {
  for_each = var.create_static_web_deployment ? { for origin in var.origins : origin.bucket_suffix => origin } : {}

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

resource "aws_cloudfront_function" "viewer_request" {
  count = var.create_static_web_deployment ? 1 : 0

  name    = "${var.static_web_deployment_name}-viewer-request"
  runtime = var.cloudfront_viewer_request_function_runtime
  publish = true
  comment = "Directory trailing-slash redirect and index.html rewrite for ${var.static_web_deployment_name}"
  code    = file("${path.module}/viewer_request.js")
}

resource "aws_cloudfront_distribution" "this" {
  count = var.create_static_web_deployment ? 1 : 0

  depends_on = [aws_s3_bucket.this, aws_cloudfront_function.viewer_request]

  dynamic "origin" {
    for_each = var.origins
    content {
      domain_name              = aws_s3_bucket.this[origin.value.bucket_suffix].bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
      origin_id                = origin.value.origin_id
    }
  }

  default_cache_behavior {
    target_origin_id       = var.default_cache_behavior.target_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # AWS Managed Cache Policy: CachingDisabled

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer_request[0].arn
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # AWS Managed Cache Policy: CachingDisabled

      function_association {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.viewer_request[0].arn
      }
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  aliases = var.aliases

  viewer_certificate {
    cloudfront_default_certificate = length(var.aliases) == 0
    acm_certificate_arn            = length(var.aliases) > 0 ? var.acm_certificate_arn : null
    ssl_support_method             = length(var.aliases) > 0 ? "sni-only" : null
    minimum_protocol_version       = length(var.aliases) > 0 ? var.cloudfront_ssl_minimum_protocol_version : null
  }

  enabled = var.enable_cloudfront_distribution

  price_class = "PriceClass_All"

  default_root_object = var.default_root_object

  tags = var.tags

  lifecycle {
    precondition {
      condition     = length(var.aliases) == 0 || var.acm_certificate_arn != ""
      error_message = "When aliases is non-empty, acm_certificate_arn must be set to an ACM certificate in us-east-1 (required by CloudFront for custom hostnames)."
    }
  }
}

resource "aws_cloudfront_origin_access_control" "this" {
  count                             = var.create_static_web_deployment ? 1 : 0
  name                              = var.static_web_deployment_name
  description                       = "Policy for ${var.static_web_deployment_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_iam_role" "github_actions_role" {
  name               = "${var.static_web_deployment_name}-deployment-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json

  inline_policy {
    name   = "s3-access-policy"
    policy = data.aws_iam_policy_document.s3_permissions.json
  }
  dynamic "inline_policy" {
    for_each = var.cloudflare_api_token_ssm_parameter_arn != "" ? [1] : []
    content {
      name   = "ssm-parameter-access-policy"
      policy = data.aws_iam_policy_document.ssm_parameter_permissions.json
    }
  }
}
