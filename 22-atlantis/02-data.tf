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

data "aws_ssm_parameter" "google_client_id" {
  name = "/common/google/client_id"

  with_decryption = true
}

data "aws_ssm_parameter" "google_client_secret" {
  name = "/common/google/client_secret"

  with_decryption = true
}

data "aws_ssm_parameter" "infracost_api_key" {
  name = "/common/infracost/api-key"

  with_decryption = true
}
