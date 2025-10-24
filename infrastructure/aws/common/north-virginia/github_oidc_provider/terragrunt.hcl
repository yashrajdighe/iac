# include "root" {
#   path   = find_in_parent_folders()
#   expose = true
# }

# include "region" {
#   path   = find_in_parent_folders("region.hcl")
#   expose = true
# }

# include "env" {
#   path   = find_in_parent_folders("env.hcl")
#   expose = true
# }

# include "account" {
#   path   = find_in_parent_folders("account.hcl")
#   expose = true
# }

# include "common_inputs" {
#   path = find_in_parent_folders("_env/github_oidc_provider.hcl")
# }

# #dependency "<resource-name>" {
# #  config_path = "../<terragrunt-file-relative-path>"

# #  mock_outputs = {
# #    # define mock outputs here
# #  }
# #}

# #dependencies {
# #  paths = ["../dependent-resource-terragrunt-file-relative-path"]
# #}

# #locals {
# # define locals here
# #}
