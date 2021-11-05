# aws_lb_listener

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn

  port            = "443"
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.this[0].arn

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

resource "aws_lb_listener_certificate" "https" {
  count = length(var.domains) > 1 ? length(var.domains) - 1 : 0

  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = data.aws_acm_certificate.this[count.index + 1].arn
}
