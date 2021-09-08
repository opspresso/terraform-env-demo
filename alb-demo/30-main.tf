# alb
# https://github.com/terraform-aws-modules/terraform-aws-alb

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.5.0"

  name = var.name

  load_balancer_type = "application"

  vpc_id          = local.vpc_id
  subnets         = local.subnet_ids
  security_groups = local.security_groups

  target_groups = [
    {
      name_prefix          = format("%s-", var.name)
      backend_protocol     = "HTTP"
      backend_port         = 8080
      target_type          = "ip"
      deregistration_delay = 5
      health_check = {
        path     = "/healthz"
        matcher  = "200-499"
        interval = 10
      }
    },
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = data.aws_acm_certificate.this.arn
      target_group_index = 0
    },
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  enable_cross_zone_load_balancing = true

  tags = {
    Environment = "demo"
  }
}
