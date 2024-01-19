# aws_lb_listener

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn

  port     = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = local.tgs
        content {
          arn    = target_group.value.internal_http
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

resource "aws_lb_listener_rule" "internal_http--loki" {
  listener_arn = aws_lb_listener.internal_http.arn
  priority     = 1

  condition {
    host_header {
      values = [format("loki.in.demo.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_http_0.arn
  }
}

resource "aws_lb_listener_rule" "internal_http--prom" {
  listener_arn = aws_lb_listener.internal_http.arn
  priority     = 2

  condition {
    host_header {
      values = [format("prom.in.demo.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_http_0.arn
  }
}

resource "aws_lb_listener_rule" "internal_http--a" {
  listener_arn = aws_lb_listener.internal_http.arn
  priority     = 11

  condition {
    host_header {
      values = [format("*.in.demo-a.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_http_a.arn
  }
}

resource "aws_lb_listener_rule" "internal_http--b" {
  listener_arn = aws_lb_listener.internal_http.arn
  priority     = 12

  condition {
    host_header {
      values = [format("*.in.demo-b.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_http_b.arn
  }
}
