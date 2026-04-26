variable "zone_id" {
  description = "Cloudflare zone ID where the DNS records will be created"
  type        = string
}

variable "tg_path" {
  description = "Terragrunt path relative to the repo terragrunt root (same value as the AWS default tag tg_path)"
  type        = string
}

variable "records" {
  description = "Map of DNS records to create. The key is used as a unique identifier for each record. Omit comment or set it to \"\" for the module default (Created by iac. TG_PATH: ...)."
  type = map(object({
    name     = string
    type     = string
    content  = string
    ttl      = optional(number, 1)
    proxied  = optional(bool, false)
    comment  = optional(string, "")
    tags     = optional(list(string), [])
    priority = optional(number)
  }))
  default = {}
}
