variable "enable_budgets" {
  description = "Enable AWS Budgets"
  type        = bool
  default     = true
}

variable "name" {
  description = "The name of the budget."
  type        = string
}

variable "limit_amount" {
  description = "The total amount of cost to budget."
  type        = string
}

variable "limit_unit" {
  description = "The unit of the budget amount."
  type        = string
  default     = "USD"
}

variable "time_unit" {
  description = "The time unit of the budget."
  type        = string
  default     = "MONTHLY"
}

variable "notification_threshold" {
  description = "The threshold for the budget notification."
  type        = number
  default     = 80
}

variable "subscriber_email_addresses" {
  description = "List of email addresses to receive budget notifications."
  type        = list(string)
  default     = [""]
}
