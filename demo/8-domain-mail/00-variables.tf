variable "region" {
  description = "SES receiving and sending region."
  type        = string
  default     = "ap-northeast-2"
}

variable "forward_to" {
  description = "Private destination mailbox; supply through an untracked tfvars file."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.forward_to)) && lower(var.forward_to) != "admin@opspresso.com"
    error_message = "Set a valid destination distinct from the receiving address."
  }
}

variable "receive_enabled" {
  description = "Switch the domain MX to SES after domain authentication and forwarding validation."
  type        = bool
  default     = false
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
