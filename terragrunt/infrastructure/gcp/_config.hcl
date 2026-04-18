locals {
  platform = "gcp"

  project = "iac"
  creator = "tofu/terragrunt"
  team    = "devops"

  wif_provider       = "projects/850812025847/locations/global/workloadIdentityPools/yashrajdighe-iac-readonly/providers/read-access"
  ci_service_account = "yashrajdighe-iac-readonly@project-c0cea0c3-cf00-4dc8-b6d.iam.gserviceaccount.com"
}
