include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/aws/aws_ssh_key_pair"
}

inputs = {
  create_ssh_key_pair = true
  key_name            = "playground-default-key"
  public_key          = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPYPZZvdSj0ey4cursd0GAcUO6IUj62Pgp++DlFskGDq devops@YashrajDighe"
}
