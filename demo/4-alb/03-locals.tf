# locals

locals {
  # HTTPS 리스너의 기본(default) 인증서로 쓸 도메인. 나머지는 SNI 로 추가됩니다.
  primary_domain = var.public_domains[0]

  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr        = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
  public_subnets  = data.terraform_remote_state.vpc.outputs.public_subnets
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  # VPC 기본 SG 는 vpc 모듈이 규칙을 모두 제거한 상태로 관리하므로 붙여도 효과가 없습니다.
  public_security_groups   = [aws_security_group.public.id]
  internal_security_groups = [aws_security_group.internal.id]

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
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/4-alb"
  }
}
