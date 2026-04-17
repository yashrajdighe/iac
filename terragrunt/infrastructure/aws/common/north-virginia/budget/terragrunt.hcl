include "root" {
  path = find_in_parent_folders()
}

include "common_inputs" {
  path = find_in_parent_folders("_env/budgets.hcl")
}

inputs = {
  name                       = "common-account-monthly-budget"
  subscriber_email_addresses = ["yashraj.dighe077+aws-budgets-notification-common@gmail.com"]
}
