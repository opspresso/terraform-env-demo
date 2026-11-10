data "aws_caller_identity" "current" {}

data "aws_route53_zone" "mail" {
  name         = local.domain
  private_zone = false
}
