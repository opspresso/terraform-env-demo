# locals

locals {
  # var.domains 를 리소스가 쓰는 형태로 폅니다.
  # certificate_domains 는 인증서 도메인 집합, *_records 는 {레코드 이름 => 그 레코드가 속한 zone} 입니다.
  certificate_domains = toset(flatten([for domain in var.domains : domain.certificates]))

  public_records = {
    for pair in flatten([
      for zone, domain in var.domains : [
        for record in domain.public : { record = record, zone = zone }
      ]
    ]) : pair.record => pair.zone
  }

  internal_records = {
    for pair in flatten([
      for zone, domain in var.domains : [
        for record in domain.internal : { record = record, zone = zone }
      ]
    ]) : pair.record => pair.zone
  }

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
