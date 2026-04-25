variable "domains" {
  description = "Domains for the certificate. The first entry is the primary domain (Common Name); additional entries become Subject Alternative Names (SANs)—for example www, api, or a wildcard such as *.example.com."
  type        = list(string)

  validation {
    condition     = length(var.domains) >= 1
    error_message = "Provide at least one domain."
  }
}

variable "validation_method" {
  description = "How ACM validates domain ownership. Use DNS for wildcards and most cases; EMAIL is also supported by ACM."
  type        = string
  default     = "DNS"

  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "validation_method must be DNS or EMAIL."
  }
}

variable "tags" {
  description = "Tags applied to the certificate."
  type        = map(string)
  default     = {}
}
