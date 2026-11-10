locals {
  # The backend and remote state blocks cannot read locals and repeat this region.
  region = "ap-northeast-2"

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
