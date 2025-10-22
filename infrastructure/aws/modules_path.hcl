locals {
  aws_modules_root = "${dirname(find_in_parent_folders("terragrunt.hcl"))}/../modules/aws"
}
