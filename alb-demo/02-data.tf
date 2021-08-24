# data

data "aws_acm_certificate" "bruce_spic_me" {
  domain      = "bruce.spic.me"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
