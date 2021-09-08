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
      name_prefix      = format("%s-", var.name)
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets          = []
    },
    # {
    #   name_prefix      = format("%s-a-", var.name)
    #   backend_protocol = "HTTP"
    #   backend_port     = 80
    #   target_type      = "instance"
    #   targets          = []
    # },
    # {
    #   name_prefix      = format("%s-b-", var.name)
    #   backend_protocol = "HTTP"
    #   backend_port     = 80
    #   target_type      = "instance"
    #   targets          = []
    # },
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = data.aws_acm_certificate.bruce_spic_me.arn
      target_group_index = 0
    },
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  tags = {
    Environment = "demo"
  }
}
