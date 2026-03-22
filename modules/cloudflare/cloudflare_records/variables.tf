variable "zone_id" {
  description = "Cloudflare zone ID where the DNS records will be created"
  type        = string
}

variable "records" {
  description = "Map of DNS records to create. The key is used as a unique identifier for each record."
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
