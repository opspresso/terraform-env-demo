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

  # Route53
  route53_zone_name = var.domain
  certificate_arn   = data.aws_acm_certificate.domain.arn

  # EFS
  enable_ephemeral_storage = true

  # ECS
  ecs_service_platform_version = "LATEST"
  ecs_container_insights       = true
  ecs_task_cpu                 = 512
  ecs_task_memory              = 1024
  container_memory_reservation = 256
  container_cpu                = 512
  container_memory             = 1024

  runtime_platform = {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  entrypoint        = ["docker-entrypoint.sh"]
  command           = ["server"]
  working_directory = "/tmp"
  docker_labels = {
    "org.opencontainers.image.title"       = "Atlantis"
    "org.opencontainers.image.description" = "A self-hosted golang application that listens for Terraform pull request events via webhooks."
    "org.opencontainers.image.url"         = "https://github.com/runatlantis/atlantis/pkgs/container/atlantis"
  }
  start_timeout = 30
  stop_timeout  = 30

  readonly_root_filesystem = false # atlantis currently mutable access to root filesystem
  ulimits = [{
    name      = "nofile"
    softLimit = 4096
    hardLimit = 16384
  }]

  # Trusted roles
  trusted_principals = ["ssm.amazonaws.com"]

  # # Infracost
  # atlantis_image   = "infracost/infracost-atlantis"
  # atlantis_version = "latest"

  # Github token
  atlantis_github_user       = var.atlantis_github_user
  atlantis_github_user_token = data.aws_ssm_parameter.github_token.value
  atlantis_repo_allowlist    = var.atlantis_repo_allowlist

  # Google auth
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
  allow_repo_config            = true

  custom_environment_variables = [
    {
      name : "ATLANTIS_REPO_CONFIG_JSON",
      value : jsonencode(yamldecode(file("${path.module}/server-atlantis.yaml"))),
    },
    {
      name : "INFRACOST_API_KEY",
      value : data.aws_ssm_parameter.infracost_api_key.value,
    },
  ]

  tags = local.tags
}
