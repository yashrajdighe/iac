terraform {
  source = "${find_in_parent_folders("modules/aws")}/aws_budgets"
}

inputs = {
  limit_amount               = "5"
  subscriber_email_addresses = ["yashraj.dighe077+aws-budgets-notification-staging@gmail.com"]
}
