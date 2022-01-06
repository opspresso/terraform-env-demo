# aws_lb_listener

resource "aws_lb_listener" "grpc" {
  load_balancer_arn = aws_lb.this.arn

  port     = "80"
  protocol = "HTTP"

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
  listener_arn = aws_lb_listener.http.arn
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
  listener_arn = aws_lb_listener.http.arn
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
