# aws_lb_target_group

resource "aws_lb_target_group" "internal_http_0" {
  name        = format("%s-in-http-0", var.name)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  slow_start  = 30
  vpc_id      = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

resource "aws_lb_target_group" "internal_http_a" {
  name        = format("%s-in-http-a", var.name)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  slow_start  = 30
  vpc_id      = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

resource "aws_lb_target_group" "internal_http_b" {
  name        = format("%s-in-http-b", var.name)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  slow_start  = 30
  vpc_id      = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

# output

output "internal_http_0" {
  value = aws_lb_target_group.internal_http_0.arn
}

output "internal_http_a" {
  value = aws_lb_target_group.internal_http_a.arn
}

output "internal_http_b" {
  value = aws_lb_target_group.internal_http_b.arn
}

# save ssm

resource "aws_ssm_parameter" "internal_http_0" {
  name  = format("/k8s/common/%s/internal_http_0", var.name)
  type  = "String"
  value = aws_lb_target_group.internal_http_0.arn
}

resource "aws_ssm_parameter" "internal_http_a" {
  name  = format("/k8s/common/%s/internal_http_a", var.name)
  type  = "String"
  value = aws_lb_target_group.internal_http_a.arn
}

resource "aws_ssm_parameter" "internal_http_b" {
  name  = format("/k8s/common/%s/internal_http_b", var.name)
  type  = "String"
  value = aws_lb_target_group.internal_http_b.arn
}
