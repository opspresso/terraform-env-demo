# route53

data "aws_route53_zone" "this" {
  for_each = var.domains

  name = each.key
}

resource "aws_route53_record" "public" {
  for_each = local.public_records

  zone_id = data.aws_route53_zone.this[each.value].zone_id
  name    = each.key
  type    = "A"

  alias {
    zone_id                = aws_lb.public.zone_id
    name                   = aws_lb.public.dns_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "internal" {
  for_each = local.internal_records

  zone_id = data.aws_route53_zone.this[each.value].zone_id
  name    = each.key
  type    = "A"

  alias {
    zone_id                = aws_lb.internal.zone_id
    name                   = aws_lb.internal.dns_name
    evaluate_target_health = false
  }
}

# The wildcard used to point at the k3s node and was owned by 8-agent-studio. Adopt the same
# record here; apply 8-agent-studio (which forgets it) before this directory.
import {
  to = aws_route53_record.public["*.agrt.dev"]
  id = "Z01936462SJ924LB2O65K_*.agrt.dev_A"
}

# The demo wildcard used to point at the k3s node (8-agent-studio). Adopt it here for the EKS ALB.
import {
  to = aws_route53_record.public["*.demo.rovr.dev"]
  id = "Z08156012ZE4O9NSKVHWK_*.demo.rovr.dev_A"
}
