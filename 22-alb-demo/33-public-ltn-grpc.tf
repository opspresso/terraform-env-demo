# aws_lb_listener

resource "aws_lb_listener" "grpc" {
  load_balancer_arn = aws_lb.this.arn

  port            = "50051"
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.this[0].arn

  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = local.tgs
        content {
          arn    = target_group.value.public_grpc
          weight = target_group.value.weight
        }
      }

      stickiness {
        enabled  = false
        duration = 600
      }
    }
  }
}

resource "aws_lb_listener_rule" "grpc--a" {
  listener_arn = aws_lb_listener.grpc.arn
  priority     = 11

  condition {
    host_header {
      values = ["*.demo-a.nalbam.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_grpc_a.arn
  }
}

resource "aws_lb_listener_rule" "grpc--b" {
  listener_arn = aws_lb_listener.grpc.arn
  priority     = 12

  condition {
    host_header {
      values = ["*.demo-b.nalbam.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_grpc_b.arn
  }
}
