variable "region" {
  description = "SES sending region."
  type        = string
  default     = "ap-northeast-2"
}

variable "cloudflare_mx_records" {
  description = "Exact MX records assigned by Cloudflare Email Routing, mirrored in the former Route 53 zone during DNS cache expiry."
  type        = list(string)

  validation {
    condition     = length(var.cloudflare_mx_records) > 0 && alltrue([for record in var.cloudflare_mx_records : can(regex("^[0-9]+ [a-z0-9-]+\\.mx\\.cloudflare\\.net\\.?$", record))])
    error_message = "Supply Cloudflare-assigned MX priorities and hostnames."
  }
}

locals {
  domain       = "opspresso.com"
  address      = "admin@${local.domain}"
  name         = "opspresso-admin-mail"
  mail_from    = "mail.${local.domain}"
  input_prefix = "incoming/"
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "mail" {
  name         = local.domain
  private_zone = false
}
