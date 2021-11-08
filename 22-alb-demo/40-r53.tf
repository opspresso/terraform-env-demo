# route53

data "aws_route53_zone" "this" {
  count = length(var.domains)

  name = var.domains[count.index]
}

resource "aws_route53_record" "this" {
  count = length(var.domains)

  zone_id = data.aws_route53_zone.this[count.index].zone_id
  name    = format("*.%s", var.domains[count.index])
  type    = "A"

  alias {
    zone_id                = aws_lb.this.zone_id
    name                   = aws_lb.this.dns_name
    evaluate_target_health = false
  }
}
