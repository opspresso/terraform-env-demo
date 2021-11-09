# locals

locals {
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnets  = data.terraform_remote_state.vpc.outputs.public_subnets
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  security_groups = [
    data.terraform_remote_state.vpc.outputs.default_security_group_id,
    aws_security_group.public.id,
  ]

  public_tgs = [
    {
      arn    = aws_lb_target_group.public_tg_0.arn
      weight = 0
    },
    {
      arn    = aws_lb_target_group.public_tg_a.arn
      weight = 1
    },
    {
      arn    = aws_lb_target_group.public_tg_b.arn
      weight = 0
    },
  ]

  internal_tgs = [
    {
      arn    = aws_lb_target_group.internal_tg_0.arn
      weight = 0
    },
    {
      arn    = aws_lb_target_group.internal_tg_a.arn
      weight = 1
    },
    {
      arn    = aws_lb_target_group.internal_tg_b.arn
      weight = 0
    },
  ]

  tags = {
    Environment = "demo"
  }
}
