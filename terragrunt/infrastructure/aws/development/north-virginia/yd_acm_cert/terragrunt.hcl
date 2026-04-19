include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "common_inputs" {
  path = find_in_parent_folders("_env/yd_acm_cert.hcl")
}
