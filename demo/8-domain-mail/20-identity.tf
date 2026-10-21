resource "aws_sesv2_email_identity" "mail" {
  email_identity = local.domain
  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = data.aws_route53_zone.mail.zone_id
  name    = "${aws_sesv2_email_identity.mail.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${local.domain}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_sesv2_email_identity.mail.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_sesv2_email_identity_mail_from_attributes" "mail" {
  email_identity         = aws_sesv2_email_identity.mail.email_identity
  mail_from_domain       = local.mail_from
  behavior_on_mx_failure = "REJECT_MESSAGE"
}

resource "aws_route53_record" "mail_from_mx" {
  zone_id = data.aws_route53_zone.mail.zone_id
  name    = local.mail_from
  type    = "MX"
  ttl     = 300
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
}

resource "aws_route53_record" "mail_from_spf" {
  zone_id = data.aws_route53_zone.mail.zone_id
  name    = local.mail_from
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.mail.zone_id
  name    = "_dmarc.${local.domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=none; adkim=r; aspf=r"]
}

resource "aws_route53_record" "mx" {
  zone_id = data.aws_route53_zone.mail.zone_id
  name    = local.domain
  type    = "MX"
  ttl     = 60
  records = var.receive_enabled ? ["10 inbound-smtp.${var.region}.amazonaws.com"] : [
    "1 mx1.larksuite.com", "5 mx2.larksuite.com", "10 mx3.larksuite.com"
  ]

  depends_on = [aws_ses_active_receipt_rule_set.mail]
}

resource "aws_route53_record" "spf" {
  zone_id = data.aws_route53_zone.mail.zone_id
  name    = local.domain
  type    = "TXT"
  ttl     = 60
  records = var.receive_enabled ? ["v=spf1 include:amazonses.com -all"] : ["v=spf1 +include:spf.onlarksuite.com -all"]
}

import {
  to = aws_route53_record.mx
  id = "Z09927883VHDFS344CJ61_opspresso.com_MX"
}

import {
  to = aws_route53_record.spf
  id = "Z09927883VHDFS344CJ61_opspresso.com_TXT"
}
