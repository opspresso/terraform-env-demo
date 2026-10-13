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

# moved
#
# 와일드카드가 변수(var.domains)에 명시되면서 for_each 키가 "demo.opspresso.com" 에서
# "*.demo.opspresso.com" 로 바뀌었습니다. 레코드 내용은 그대로이므로 destroy/create 대신
# state 만 옮깁니다. apply 이후에는 지워도 됩니다.

moved {
  from = aws_route53_record.public["demo.opspresso.com"]
  to   = aws_route53_record.public["*.demo.opspresso.com"]
}

moved {
  from = aws_route53_record.public["demo-a.opspresso.com"]
  to   = aws_route53_record.public["*.demo-a.opspresso.com"]
}

moved {
  from = aws_route53_record.public["demo-b.opspresso.com"]
  to   = aws_route53_record.public["*.demo-b.opspresso.com"]
}

moved {
  from = aws_route53_record.internal["demo-in.opspresso.com"]
  to   = aws_route53_record.internal["*.demo-in.opspresso.com"]
}

moved {
  from = aws_route53_record.internal["demo-in-a.opspresso.com"]
  to   = aws_route53_record.internal["*.demo-in-a.opspresso.com"]
}

moved {
  from = aws_route53_record.internal["demo-in-b.opspresso.com"]
  to   = aws_route53_record.internal["*.demo-in-b.opspresso.com"]
}
