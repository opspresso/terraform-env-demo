# route53

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = format("*.%s", var.domain)
  type    = "A"

  alias {
    zone_id                = module.alb.lb_zone_id
    name                   = module.alb.lb_dns_name
    evaluate_target_health = false
  }
}
