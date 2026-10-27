# ACM certificates this directory issues (var.issued_certificates), validated through Route53.
# Each covers the domain and one wildcard level under it, e.g. demo.rovr.dev and *.demo.rovr.dev.

locals {
  # The zone is the domains key whose certificates list contains the issued domain.
  issued_certificate_zones = {
    for domain in var.issued_certificates : domain => one([for zone, value in var.domains : zone if contains(value.certificates, domain)])
  }

  certificate_arns = merge(
    { for domain, cert in data.aws_acm_certificate.public_https : domain => cert.arn },
    { for domain, validation in aws_acm_certificate_validation.issued : domain => validation.certificate_arn },
  )
}

resource "aws_acm_certificate" "issued" {
  for_each = toset(var.issued_certificates)

  domain_name               = each.value
  subject_alternative_names = [format("*.%s", each.value)]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# The domain and its wildcard share one validation record; allow_overwrite lets both keys write it.
resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for item in flatten([
      for domain, cert in aws_acm_certificate.issued : [
        for option in cert.domain_validation_options : {
          key    = option.domain_name
          zone   = local.issued_certificate_zones[domain]
          name   = option.resource_record_name
          type   = option.resource_record_type
          record = option.resource_record_value
        }
      ]
    ]) : item.key => item
  }

  zone_id         = data.aws_route53_zone.this[each.value.zone].zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 300
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "issued" {
  for_each = aws_acm_certificate.issued

  certificate_arn = each.value.arn
  validation_record_fqdns = [
    for option in each.value.domain_validation_options : option.resource_record_name
  ]

  depends_on = [aws_route53_record.certificate_validation]
}
