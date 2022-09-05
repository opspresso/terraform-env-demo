# data

data "aws_acm_certificate" "domain" {
  domain      = var.domain
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

data "aws_ssm_parameter" "github_token" {
  name = format("/common/github/%s/token", var.atlantis_github_user)

  with_decryption = true
}
