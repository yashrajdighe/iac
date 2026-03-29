locals {
  org_id          = "497943429829"
  org_name        = "yashrajdighe-dev-org"
  service_account = "yashrajdighe-iac-readonly@project-c0cea0c3-cf00-4dc8-b6d.iam.gserviceaccount.com"
  # Project that holds the Terraform state bucket — mirrors account_name in account.hcl for AWS.
  state_project_name = "management"
}
