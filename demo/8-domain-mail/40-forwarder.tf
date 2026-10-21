resource "aws_iam_role" "forwarder" {
  name = local.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "forwarder" {
  role = aws_iam_role.forwarder.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.forwarder.arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectTagging", "s3:PutObjectTagging"]
        Resource = "${aws_s3_bucket.mail.arn}/${local.input_prefix}*"
      },
      {
        Effect = "Allow"
        # SESv2 SendEmail with Content.Raw is authorized as SendRawEmail.
        Action   = "ses:SendRawEmail"
        Resource = aws_sesv2_email_identity.mail.arn
        Condition = {
          StringEquals                = { "ses:FromAddress" = local.address }
          "ForAllValues:StringEquals" = { "ses:Recipients" = [var.forward_to] }
        }
      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.failures.arn
      }
    ]
  })
}

data "archive_file" "forwarder" {
  type        = "zip"
  source_file = "${path.module}/forwarder.py"
  output_path = "${path.module}/.build/forwarder.zip"
}

resource "aws_lambda_function" "forwarder" {
  function_name                  = local.name
  role                           = aws_iam_role.forwarder.arn
  runtime                        = "python3.13"
  architectures                  = ["arm64"]
  handler                        = "forwarder.handler"
  filename                       = data.archive_file.forwarder.output_path
  source_code_hash               = data.archive_file.forwarder.output_base64sha256
  memory_size                    = 256
  timeout                        = 60
  reserved_concurrent_executions = 2

  environment {
    variables = {
      MAIL_BUCKET  = aws_s3_bucket.mail.id
      MAIL_PREFIX  = local.input_prefix
      MAIL_ADDRESS = local.address
      FORWARD_TO   = var.forward_to
    }
  }
  dead_letter_config {
    target_arn = aws_sqs_queue.failures.arn
  }
  depends_on = [aws_iam_role_policy.forwarder, aws_cloudwatch_log_group.forwarder]
}

resource "aws_lambda_function_event_invoke_config" "forwarder" {
  function_name                = aws_lambda_function.forwarder.function_name
  maximum_event_age_in_seconds = 21600
  maximum_retry_attempts       = 2
}

resource "aws_lambda_permission" "ses" {
  statement_id   = "AllowSESReceipt"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.forwarder.function_name
  principal      = "ses.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/${local.name}:receipt-rule/admin"
}

resource "aws_ses_receipt_rule_set" "mail" {
  rule_set_name = local.name
}

resource "aws_ses_receipt_rule" "admin" {
  name          = "admin"
  rule_set_name = aws_ses_receipt_rule_set.mail.rule_set_name
  recipients    = [local.address]
  enabled       = true
  scan_enabled  = true
  tls_policy    = "Optional"

  s3_action {
    position          = 1
    bucket_name       = aws_s3_bucket.mail.id
    object_key_prefix = local.input_prefix
  }
  lambda_action {
    position        = 2
    function_arn    = aws_lambda_function.forwarder.arn
    invocation_type = "Event"
  }
  stop_action {
    position = 3
    scope    = "RuleSet"
  }
  depends_on = [
    aws_s3_bucket_policy.mail,
    aws_s3_bucket_server_side_encryption_configuration.mail,
    aws_lambda_permission.ses,
    aws_lambda_function_event_invoke_config.forwarder,
  ]
}

resource "aws_ses_active_receipt_rule_set" "mail" {
  rule_set_name = aws_ses_receipt_rule_set.mail.rule_set_name
  depends_on    = [aws_ses_receipt_rule.admin]
}
