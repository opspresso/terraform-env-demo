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

output "failure_queue_url" {
  value = aws_sqs_queue.failures.url
}

output "function_name" {
  value = aws_lambda_function.forwarder.function_name
}

output "receiving_enabled" {
  value = var.receive_enabled
}
