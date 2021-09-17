# locals

locals {
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnets

  security_groups = [
    data.terraform_remote_state.vpc.outputs.default_security_group_id,
    aws_security_group.public.id,
  ]

  target_groups = [
    {
      arn    = aws_lb_target_group.default.arn
      weight = 100
    },
    {
      arn    = aws_lb_target_group.a.arn
      weight = 0
    },
    {
      arn    = aws_lb_target_group.b.arn
      weight = 0
    },
  ]

  tags = {
    Environment = "demo"
  }
}
