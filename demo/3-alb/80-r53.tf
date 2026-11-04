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

# The wildcard previously pointed at the k3s node and was owned by 8-agent-studio. Before importing,
# confirm the record is no longer in the terraform-env-apps/demo/8-agent-studio state.
import {
  to = aws_route53_record.public["*.agrt.dev"]
  id = "Z01936462SJ924LB2O65K_*.agrt.dev_A"
}
