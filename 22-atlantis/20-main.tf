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

  # DNS (without trailing dot)
  route53_zone_name = var.domain

  # ACM (SSL certificate) - Specify ARN of an existing certificate or new one will be created and validated using Route53 DNS
  certificate_arn = data.aws_acm_certificate.domain.arn

  # Atlantis
  atlantis_github_user       = var.atlantis_github_user
  atlantis_github_user_token = data.aws_ssm_parameter.github_token.value
  atlantis_repo_allowlist    = var.atlantis_repo_allowlist

  tags = local.tags
}
