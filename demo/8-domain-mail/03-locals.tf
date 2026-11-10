locals {
  domain       = "opspresso.com"
  address      = "admin@${local.domain}"
  name         = "opspresso-admin-mail"
  mail_from    = "mail.${local.domain}"
  input_prefix = "incoming/"

  tags = {
    ManagedBy = "Terraform"
    Project   = "terraform-env-demo/demo/8-domain-mail"
  }
}
