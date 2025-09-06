include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include "account" {
  path   = find_in_parent_folders("account.hcl")
  expose = true
}

terraform {
  source = "../../../../../modules/aws/aws_ssh_key_pair"
}

inputs = {
  # define module inputs here
  create_ssh_key_pair = false
  key_name            = "playground-default-key"
  public_key          = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPYPZZvdSj0ey4cursd0GAcUO6IUj62Pgp++DlFskGDq devops@YashrajDighe"
}
