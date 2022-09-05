# atlantis
# https://github.com/terraform-aws-modules/terraform-aws-atlantis

module "atlantis" {
  source  = "terraform-aws-modules/atlantis/aws"
  version = "~> 3.0"

  name = var.name

  # VPC
  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids
  public_subnet_ids  = local.public_subnet_ids

  cidr = local.vpc_cidr_block

  route53_zone_name = var.domain
  certificate_arn   = data.aws_acm_certificate.domain.arn

  readonly_root_filesystem = false # atlantis currently mutable access to root filesystem
  ulimits = [{
    name      = "nofile"
    softLimit = 4096
    hardLimit = 16384
  }]

  # Atlantis github
  atlantis_github_user       = var.atlantis_github_user
  atlantis_github_user_token = data.aws_ssm_parameter.github_token.value
  atlantis_repo_allowlist    = var.atlantis_repo_allowlist

  alb_authenticate_oidc = {
    issuer                              = "https://accounts.google.com"
    token_endpoint                      = "https://oauth2.googleapis.com/token"
    user_info_endpoint                  = "https://openidconnect.googleapis.com/v1/userinfo"
    authorization_endpoint              = "https://accounts.google.com/o/oauth2/v2/auth"
    authentication_request_extra_params = {}
    client_id                           = data.aws_ssm_parameter.google_client_id.value
    client_secret                       = data.aws_ssm_parameter.google_client_secret.value
  }

  allow_unauthenticated_access = true
  allow_github_webhooks        = true

  tags = local.tags
}
