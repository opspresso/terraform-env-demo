# aws_lb_listener

resource "aws_lb_listener" "internal_https" {
  load_balancer_arn = aws_lb.internal.arn

  port            = "443"
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.public_https[0].arn

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

resource "aws_lb_listener_rule" "internal_https--a" {
  listener_arn = aws_lb_listener.internal_https.arn
  priority     = 11

  condition {
    host_header {
      values = ["*.in.demo-a.nalbam.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_http_a.arn
  }
}

resource "aws_lb_listener_rule" "internal_https--b" {
  listener_arn = aws_lb_listener.internal_https.arn
  priority     = 12

  condition {
    host_header {
      values = ["*.in.demo-b.nalbam.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_http_b.arn
  }
}
