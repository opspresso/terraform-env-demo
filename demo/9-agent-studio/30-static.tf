# S3 — 아티팩트와 이미지를 담는 정적 버킷

# 런이 남긴 그림·문서가 여기 들어가고, 브라우저가 직접 읽습니다.
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

# 정책으로 공개 읽기를 허용하므로 `block_public_policy` 는 꺼 둡니다. ACL 쪽은 막아 둔
# 채로입니다 — 공개는 정책 한 줄로만 일어나야 추적됩니다.
resource "aws_s3_bucket_public_access_block" "static" {
  for_each = local.names

  bucket = aws_s3_bucket.static[each.key].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
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

# 서명 URL 없이 <img src> 로 읽히는 것이 이 버킷의 용도입니다. 쓰기는 파드 롤만 할 수
# 있습니다 (demo/4-role 의 agent-studio 정책).
resource "aws_s3_bucket_policy" "static" {
  for_each = local.names

  bucket = aws_s3_bucket.static[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static[each.key].arn}/*"
      },
    ]
  })

  # 새 버킷은 계정 기본값으로 공개 정책이 막힌 채 생기므로, 위 블록이 먼저 풀려야
  # 이 정책이 받아들여집니다.
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
