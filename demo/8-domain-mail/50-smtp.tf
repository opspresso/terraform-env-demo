resource "aws_iam_user" "smtp" {
  name = "${local.name}-smtp"
}

resource "aws_iam_user_policy" "smtp" {
  name = "send-admin-mail-only"
  user = aws_iam_user.smtp.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ses:SendRawEmail"
      Resource = aws_sesv2_email_identity.mail.arn
      Condition = {
        StringEquals = { "ses:FromAddress" = local.address }
      }
    }]
  })
}
