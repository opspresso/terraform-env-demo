variable "cloudflare_mx_records" {
  description = "Exact MX records assigned by Cloudflare Email Routing, mirrored in the former Route 53 zone during DNS cache expiry."
  type        = list(string)
  default = [
    "27 route1.mx.cloudflare.net",
    "29 route3.mx.cloudflare.net",
    "58 route2.mx.cloudflare.net",
  ]

  validation {
    condition     = length(var.cloudflare_mx_records) > 0 && alltrue([for record in var.cloudflare_mx_records : can(regex("^[0-9]+ [a-z0-9-]+\\.mx\\.cloudflare\\.net\\.?$", record))])
    error_message = "Supply Cloudflare-assigned MX priorities and hostnames."
  }
}
