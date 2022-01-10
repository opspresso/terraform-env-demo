# aws_lb_target_group

resource "aws_lb_target_group" "internal_http2_0" {
  name             = format("%s-in-http2-0", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP2"
  target_type      = "ip"
  vpc_id           = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

resource "aws_lb_target_group" "internal_http2_a" {
  name             = format("%s-in-http2-a", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP2"
  target_type      = "ip"
  vpc_id           = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

resource "aws_lb_target_group" "internal_http2_b" {
  name             = format("%s-in-http2-b", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP2"
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

output "internal_http2_0" {
  value = aws_lb_target_group.internal_http2_0.arn
}

output "internal_http2_a" {
  value = aws_lb_target_group.internal_http2_a.arn
}

output "internal_http2_b" {
  value = aws_lb_target_group.internal_http2_b.arn
}
