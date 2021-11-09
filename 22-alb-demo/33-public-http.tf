# aws_lb_listener

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn

  port     = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = local.public_tgs
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

resource "aws_lb_listener_rule" "http--grafana" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    host_header {
      values = ["grafana.demo.spic.me"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg_0.arn
  }
}

resource "aws_lb_listener_rule" "http--a" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 11

  condition {
    host_header {
      values = ["*.demo-a.spic.me"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg_a.arn
  }
}

resource "aws_lb_listener_rule" "http--b" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 12

  condition {
    host_header {
      values = ["*.demo-b.spic.me"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg_b.arn
  }
}