output "mail_address" {
  value = local.address
}

output "smtp_host" {
  value = "email-smtp.${var.region}.amazonaws.com"
}

output "smtp_iam_user" {
  value = aws_iam_user.smtp.name
}

output "mail_bucket" {
  value = aws_s3_bucket.mail.id
}

output "ses_dns_records" {
  description = "SES authentication records to preserve in authoritative Cloudflare DNS."
  value = concat(
    [for record in aws_route53_record.dkim : { name = record.name, type = record.type, records = record.records }],
    [for record in [aws_route53_record.mail_from_mx, aws_route53_record.mail_from_spf, aws_route53_record.dmarc] : {
      name = record.name, type = record.type, records = record.records
    }]
  )
}
