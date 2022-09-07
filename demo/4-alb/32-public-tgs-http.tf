# aws_lb_target_group

resource "aws_lb_target_group" "public_http_0" {
  name             = format("%s-http-0", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1" # [GRPC, HTTP1, HTTP2]
  slow_start       = 30
  target_type      = "ip"
  vpc_id           = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

resource "aws_lb_target_group" "public_http_a" {
  name             = format("%s-http-a", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1" # [GRPC, HTTP1, HTTP2]
  slow_start       = 30
  target_type      = "ip"
  vpc_id           = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

resource "aws_lb_target_group" "public_http_b" {
  name             = format("%s-http-b", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1" # [GRPC, HTTP1, HTTP2]
  slow_start       = 30
  target_type      = "ip"
  vpc_id           = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

# output

output "public_http_0" {
  value = aws_lb_target_group.public_http_0.arn
}

output "public_http_a" {
  value = aws_lb_target_group.public_http_a.arn
}

output "public_http_b" {
  value = aws_lb_target_group.public_http_b.arn
}

# save ssm

resource "aws_ssm_parameter" "public_http_0" {
  name  = format("/k8s/common/%s/public_http_0", var.name)
  type  = "String"
  value = aws_lb_target_group.public_http_0.arn
}

resource "aws_ssm_parameter" "public_http_a" {
  name  = format("/k8s/common/%s/public_http_a", var.name)
  type  = "String"
  value = aws_lb_target_group.public_http_a.arn
}

resource "aws_ssm_parameter" "public_http_b" {
  name  = format("/k8s/common/%s/public_http_b", var.name)
  type  = "String"
  value = aws_lb_target_group.public_http_b.arn
}
