terraform {
  source = "${find_in_parent_folders("modules/aws")}/aws_budgets"
}

inputs = {
  limit_amount               = "1000"
  subscriber_email_addresses = ["yashraj.dighe077+aws-budgets-notification-staging@gmail.com"]
}
