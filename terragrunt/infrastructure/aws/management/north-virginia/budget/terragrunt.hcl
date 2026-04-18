include "root" {
  path = find_in_parent_folders()
}

include "common_inputs" {
  path = find_in_parent_folders("_env/budgets.hcl")
}

inputs = {
  name                       = "management-account-monthly-budget"
  subscriber_email_addresses = ["yashraj.dighe077+aws-budgets-notification-management@gmail.com"]
  limit_amount               = "25"
}
