# aws_lb_listener

resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn

  port     = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = local.internal_tgs
        content {
          arn    = target_group.value.arn
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

resource "aws_lb_listener_rule" "internal--a" {
  listener_arn = aws_lb_listener.internal.arn
  priority     = 11

  condition {
    host_header {
      values = ["*.demo-a.internal"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_tg_a.arn
  }
}

resource "aws_lb_listener_rule" "internal--b" {
  listener_arn = aws_lb_listener.internal.arn
  priority     = 12

  condition {
    host_header {
      values = ["*.demo-b.internal"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_tg_b.arn
  }
}
