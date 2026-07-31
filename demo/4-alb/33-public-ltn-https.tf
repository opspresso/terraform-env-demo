# aws_lb_listener

resource "aws_lb_listener" "public_https" {
  load_balancer_arn = aws_lb.public.arn

  port            = "443"
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = data.aws_acm_certificate.public_https[local.primary_domain].arn

  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = local.tgs
        content {
          arn    = target_group.value.public_http
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

resource "aws_lb_listener_rule" "public_https--argocd" {
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 1

  condition {
    host_header {
      values = [format("argocd.demo.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_http_0.arn
  }
}

resource "aws_lb_listener_rule" "public_https--workflows" {
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 3

  condition {
    host_header {
      values = [format("workflows.demo.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_http_0.arn
  }
}

resource "aws_lb_listener_rule" "public_https--grafana" {
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 5

  condition {
    host_header {
      values = [format("grafana.demo.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_http_0.arn
  }
}

# The one host that needs HTTP/2 all the way to the backend. Everything else
# falls through to the default action, which is the HTTP1 group — see
# 34-public-tgs-grpc.tf for why one group cannot serve both.
resource "aws_lb_listener_rule" "public_https--sample-grpc" {
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 7

  condition {
    host_header {
      values = [format("sample-grpc.demo.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_grpc_0.arn
  }
}

resource "aws_lb_listener_rule" "public_https--a" {
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 11

  condition {
    host_header {
      values = [format("*.demo-a.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_http_a.arn
  }
}

resource "aws_lb_listener_rule" "public_https--b" {
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 12

  condition {
    host_header {
      values = [format("*.demo-b.%s", var.root_domain)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_http_b.arn
  }
}

# acm

data "aws_acm_certificate" "public_https" {
  for_each = toset(var.public_domains)

  domain      = each.value
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

# 기본 인증서(local.primary_domain)를 제외한 나머지는 SNI 추가 인증서로 붙입니다.
resource "aws_lb_listener_certificate" "public_https" {
  for_each = toset([for domain in var.public_domains : domain if domain != local.primary_domain])

  listener_arn    = aws_lb_listener.public_https.arn
  certificate_arn = data.aws_acm_certificate.public_https[each.value].arn
}
