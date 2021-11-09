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

resource "aws_lb_listener_rule" "internal--loki" {
  listener_arn = aws_lb_listener.internal.arn
  priority     = 1

  condition {
    host_header {
      values = ["loki.in.demo.spic.me"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_tg_0.arn
  }
}

resource "aws_lb_listener_rule" "internal--prom" {
  listener_arn = aws_lb_listener.internal.arn
  priority     = 2

  condition {
    host_header {
      values = ["prom.in.demo.spic.me"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_tg_0.arn
  }
}

resource "aws_lb_listener_rule" "internal--a" {
  listener_arn = aws_lb_listener.internal.arn
  priority     = 11

  condition {
    host_header {
      values = ["*.in.demo-a.spic.me"]
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
      values = ["*.in.demo-b.spic.me"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_tg_b.arn
  }
}