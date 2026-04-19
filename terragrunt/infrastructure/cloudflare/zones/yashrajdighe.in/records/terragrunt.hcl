include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "my_portfolio" {
  config_path = "../../../../aws/development/north-virginia/my-portfolio"

  mock_outputs = {
    cloudfront_distribution_domain_name = "d111111abcdef8.cloudfront.net"
  }
}

dependencies {
  paths = ["../../../../aws/development/north-virginia/my-portfolio"]
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
      content = dependency.my_portfolio.outputs.cloudfront_distribution_domain_name
      proxied = true
    }
  }
}
