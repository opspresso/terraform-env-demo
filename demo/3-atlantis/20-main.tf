# atlantis
# https://github.com/terraform-aws-modules/terraform-aws-atlantis

module "atlantis" {
  source  = "terraform-aws-modules/atlantis/aws"
  version = "~> 4.0"

  name = var.name

  # VPC
  vpc_id          = local.vpc_id
  service_subnets = local.private_subnet_ids

  # ALB
  alb = {
    # For example only
    enable_deletion_protection = false
  }
  alb_subnets = local.public_subnet_ids

  # ACM
  certificate_domain_name = var.domain
  route53_zone_id         = data.aws_route53_zone.this.zone_id

  # ECS Service
  service = {
    task_exec_secret_arns = [
      "arn:aws:secretsmanager:eu-west-1:111122223333:secret:aes256-7g8H9i",
      "arn:aws:secretsmanager:eu-west-1:111122223333:secret:aes192-4D5e6F",
    ]
    # Provide Atlantis permission necessary to create/destroy resources
    tasks_iam_role_policies = {
      AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
  }

  # ECS Container Definition
  atlantis = {
    environment = [
      {
        name  = "ATLANTIS_GH_USER"
        value = var.atlantis_github_user
      },
      {
        name  = "ATLANTIS_REPO_ALLOWLIST"
        value = join(",", var.atlantis_repo_allowlist)
      },
      {
        name  = "ATLANTIS_ENABLE_DIFF_MARKDOWN_FORMAT"
        value = "true"
      },
    ]
    secrets = [
      {
        name      = "ATLANTIS_GH_TOKEN"
        valueFrom = "arn:aws:secretsmanager:eu-west-1:111122223333:secret:aes256-7g8H9i"
      },
      {
        name      = "ATLANTIS_GH_WEBHOOK_SECRET"
        valueFrom = "arn:aws:secretsmanager:eu-west-1:111122223333:secret:aes192-4D5e6F"
      },
    ]
  }

  tags = local.tags
}
