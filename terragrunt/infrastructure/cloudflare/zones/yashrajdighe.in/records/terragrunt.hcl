include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "my_portfolio_development" {
  config_path = "../../../../aws/development/north-virginia/my-portfolio"

  mock_outputs = {
    cloudfront_distribution_domain_name = "d111111abcdef8.cloudfront.net"
  }

  # Merge mocks into existing state so new root outputs (not yet in state) do not break parsing.
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "my_portfolio_staging" {
  config_path = "../../../../aws/staging/north-virginia/my-portfolio"

  mock_outputs = {
    cloudfront_distribution_domain_name = "d111111abcdef8.cloudfront.net"
  }

  mock_outputs_merge_strategy_with_state = "shallow"
}


dependency "yd_acm_cert_development" {
  config_path = "../../../../aws/development/north-virginia/yd_acm_cert"

  mock_outputs = {
    domain_validation_options = [
      {
        domain_name           = "*.yashrajdighe.in"
        resource_record_name  = "_mock-dev.acm-validations.aws"
        resource_record_type  = "CNAME"
        resource_record_value = "mock-dev.acm-validations.aws"
      }
    ]
  }

  # Merge mocks into existing state so new root outputs (not yet in state) do not break parsing.
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "yd_acm_cert_staging" {
  config_path = "../../../../aws/staging/north-virginia/yd_acm_cert"

  mock_outputs = {
    domain_validation_options = [
      {
        domain_name           = "*.yashrajdighe.in"
        resource_record_name  = "_mock-stg.acm-validations.aws"
        resource_record_type  = "CNAME"
        resource_record_value = "mock-stg.acm-validations.aws"
      }
    ]
  }

  # Merge mocks into existing state so new root outputs (not yet in state) do not break parsing.
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "yd_acm_cert_production" {
  config_path = "../../../../aws/production/north-virginia/yd_acm_cert"

  # ACM still returns one DVO per subject name, but apex + wildcard often share the same CNAME; mocks mirror that.
  mock_outputs = {
    domain_validation_options = [
      {
        domain_name           = "*.yashrajdighe.in"
        resource_record_name  = "_mock-prod.acm-validations.aws"
        resource_record_type  = "CNAME"
        resource_record_value = "mock-prod.acm-validations.aws"
      },
      {
        domain_name           = "yashrajdighe.in"
        resource_record_name  = "_mock-prod.acm-validations.aws"
        resource_record_type  = "CNAME"
        resource_record_value = "mock-prod.acm-validations.aws"
      }
    ]
  }

  # Merge mocks into existing state so new root outputs (not yet in state) do not break parsing.
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependencies {
  paths = [
    "../../../../aws/development/north-virginia/my-portfolio",
    "../../../../aws/development/north-virginia/yd_acm_cert",
    "../../../../aws/staging/north-virginia/yd_acm_cert",
    "../../../../aws/production/north-virginia/yd_acm_cert",
  ]
}

terraform {
  source = "${find_in_parent_folders("modules")}/cloudflare/cloudflare_records"
}

inputs = {
  zone_id = include.root.locals.hierarchy.zone.zone_id
  records = {
    "test-iac" = {
      name    = "test-iac"
      type    = "A"
      content = "103.101.109.99"
      proxied = true
    }
    "my-portfolio-dev" = {
      name    = "dev"
      type    = "CNAME"
      content = dependency.my_portfolio_development.outputs.cloudfront_distribution_domain_name
      proxied = true
    }
    "my-portfolio-staging" = {
      name    = "staging"
      type    = "CNAME"
      content = dependency.my_portfolio_staging.outputs.cloudfront_distribution_domain_name
      proxied = true
    }
    "*-yashrajdighe-in-cert-verification-development" = {
      name = one(
        tolist(dependency.yd_acm_cert_development.outputs.domain_validation_options)
      ).resource_record_name
      type = one(
        tolist(dependency.yd_acm_cert_development.outputs.domain_validation_options)
      ).resource_record_type
      content = one(
        tolist(dependency.yd_acm_cert_development.outputs.domain_validation_options)
      ).resource_record_value
      proxied = false
    }
    "*-yashrajdighe-in-cert-verification-staging" = {
      name = one(
        tolist(dependency.yd_acm_cert_staging.outputs.domain_validation_options)
      ).resource_record_name
      type = one(
        tolist(dependency.yd_acm_cert_staging.outputs.domain_validation_options)
      ).resource_record_type
      content = one(
        tolist(dependency.yd_acm_cert_staging.outputs.domain_validation_options)
      ).resource_record_value
      proxied = false
    }
    # Production includes apex + wildcard. ACM emits two DVOs that often share the same CNAME. Duplicate
    # resource_record_name values must use => o... (grouping); then take any element — they are equivalent.
    "*-yashrajdighe-in-cert-verification-production" = {
      name = element(
        one(values({
          for o in tolist(dependency.yd_acm_cert_production.outputs.domain_validation_options) : o.resource_record_name => o...
        })),
        0
      ).resource_record_name
      type = element(
        one(values({
          for o in tolist(dependency.yd_acm_cert_production.outputs.domain_validation_options) : o.resource_record_name => o...
        })),
        0
      ).resource_record_type
      content = element(
        one(values({
          for o in tolist(dependency.yd_acm_cert_production.outputs.domain_validation_options) : o.resource_record_name => o...
        })),
        0
      ).resource_record_value
      proxied = false
    }
  }
}
