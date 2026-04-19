resource "aws_acm_certificate" "this" {
  domain_name               = var.domains[0]
  subject_alternative_names = length(var.domains) > 1 ? slice(var.domains, 1, length(var.domains)) : []

  validation_method = var.validation_method

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}
