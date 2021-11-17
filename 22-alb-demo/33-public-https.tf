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

resource "aws_lb_listener_rule" "https--argocd" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  condition {
    host_header {
      values = ["argocd.demo.nalbam.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg_0.arn
  }
}

resource "aws_lb_listener_rule" "https--grafana" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  condition {
    host_header {
      values = ["grafana.demo.nalbam.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg_0.arn
  }
}

resource "aws_lb_listener_rule" "https--a" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 11

  condition {
    host_header {
      values = ["*.demo-a.nalbam.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg_a.arn
  }
}

resource "aws_lb_listener_rule" "https--b" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 12

  condition {
    host_header {
      values = ["*.demo-b.nalbam.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg_b.arn
  }
}

# acm

data "aws_acm_certificate" "this" {
  count = length(var.domains)

  domain      = var.domains[count.index]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

resource "aws_lb_listener_certificate" "https" {
  count = length(var.domains) > 1 ? length(var.domains) - 1 : 0

  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = data.aws_acm_certificate.this[count.index + 1].arn
}
