# route53

data "aws_route53_zone" "this" {
  name = var.root_domain
}

resource "aws_route53_record" "public" {
  for_each = toset(var.domains)

  zone_id = data.aws_route53_zone.this.zone_id
  name    = format("*.%s", each.value)
  type    = "A"

  alias {
    zone_id                = aws_lb.public.zone_id
    name                   = aws_lb.public.dns_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "internal" {
  for_each = toset(var.domains)

  zone_id = data.aws_route53_zone.this.zone_id
  name    = format("*.in.%s", each.value)
  type    = "A"

  alias {
    zone_id                = aws_lb.internal.zone_id
    name                   = aws_lb.internal.dns_name
    evaluate_target_health = false
  }
}
