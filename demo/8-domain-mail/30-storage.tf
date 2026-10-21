resource "aws_s3_bucket" "mail" {
  bucket = "${local.name}-${data.aws_caller_identity.current.account_id}-${var.region}"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "mail" {
  bucket                  = aws_s3_bucket.mail.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mail" {
  bucket = aws_s3_bucket.mail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mail" {
  bucket = aws_s3_bucket.mail.id
  rule {
    id     = "retain-undelivered-mail-30-days"
    status = "Enabled"
    filter {
      prefix = local.input_prefix
    }
    expiration {
      days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
  rule {
    id     = "expire-forwarded-mail-after-7-days"
    status = "Enabled"
    filter {
      tag {
        key   = "delivery"
        value = "forwarded"
      }
    }
    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_policy" "mail" {
  bucket = aws_s3_bucket.mail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ReceiveMailFromSES"
        Effect    = "Allow"
        Principal = { Service = "ses.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.mail.arn}/${local.input_prefix}*"
        Condition = {
          StringEquals = { "AWS:SourceAccount" = data.aws_caller_identity.current.account_id }
          ArnEquals = {
            "AWS:SourceArn" = "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/${local.name}:receipt-rule/admin"
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.mail.arn, "${aws_s3_bucket.mail.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.mail]
}

resource "aws_sqs_queue" "failures" {
  name                      = "${local.name}-failures"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}

resource "aws_cloudwatch_log_group" "forwarder" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 7
}
