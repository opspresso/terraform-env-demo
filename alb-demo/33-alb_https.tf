# aws_lb_listener

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn

  port            = "443"
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.this.arn

  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = local.target_groups
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
