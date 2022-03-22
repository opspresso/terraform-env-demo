# locals

locals {
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnets  = data.terraform_remote_state.vpc.outputs.public_subnets
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  security_groups = [
    data.terraform_remote_state.vpc.outputs.default_security_group_id,
    aws_security_group.public.id,
  ]

  tgs = [
    {
      public_http   = aws_lb_target_group.public_http_0.arn
      internal_http = aws_lb_target_group.internal_http_0.arn
      weight        = 1
    },
    {
      public_http   = aws_lb_target_group.public_http_a.arn
      internal_http = aws_lb_target_group.internal_http_a.arn
      weight        = 0
    },
    {
      public_http   = aws_lb_target_group.public_http_b.arn
      internal_http = aws_lb_target_group.internal_http_b.arn
      weight        = 0
    },
  ]

  tags = {
    Name        = var.name
    Environment = "demo"
  }
}
