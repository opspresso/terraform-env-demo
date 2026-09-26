# S3 — Studio 아티팩트와 Memory 문서 원본을 담는 비공개 버킷

# 객체 접근은 각 앱의 인증·권한 검사와 Pod Identity를 거칩니다.
resource "aws_s3_bucket" "static" {
  for_each = local.names

  bucket = each.value.static

  tags = {
    Name = each.value.static
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 앱이 proxied 접근을 제공하므로 공개 정책과 ACL을 모두 차단합니다.
resource "aws_s3_bucket_public_access_block" "static" {
  for_each = local.names

  bucket = aws_s3_bucket.static[each.key].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  for_each = local.names

  bucket = aws_s3_bucket.static[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled       = false
    blocked_encryption_types = ["SSE-C"]
  }
}

# Bucket policy는 TLS만 강제하고, 접근 권한은 각 앱의 IAM policy에 둡니다.
resource "aws_s3_bucket_policy" "static" {
  for_each = local.names

  bucket = aws_s3_bucket.static[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.static[each.key].arn, "${aws_s3_bucket.static[each.key].arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.static]
}

# 보관 기간은 운영의 것입니다 — 앱은 객체를 지우지 않고, 만료는 여기서만 일어납니다.
resource "aws_s3_bucket_lifecycle_configuration" "static" {
  for_each = local.names

  bucket = aws_s3_bucket.static[each.key].id

  rule {
    id     = "artifacts-image-180d"
    status = "Enabled"
    filter {
      prefix = "artifacts/image/"
    }
    expiration {
      days = 180
    }
  }

  rule {
    id     = "artifacts-document-180d"
    status = "Enabled"
    filter {
      prefix = "artifacts/document/"
    }
    expiration {
      days = 180
    }
  }

  # 아티팩트 테이블이 생기기 전 채팅 그림이 있던 자리.
  rule {
    id     = "legacy-chat-images-180d"
    status = "Enabled"
    filter {
      prefix = "images/"
    }
    expiration {
      days = 180
    }
  }

  rule {
    id     = "abort-incomplete-uploads-7d"
    status = "Enabled"
    filter {
      prefix = ""
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
