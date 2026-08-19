# S3 — Knowledge Base 가 읽어들일 문서

# 정적 버킷과 달리 전면 비공개입니다. 여기 든 문서는 KB 를 통해서만 읽히고, 답변에
# 인용되어 나갑니다 — 원문이 링크로 공개되는 자리가 아닙니다.
resource "aws_s3_bucket" "documents" {
  for_each = local.names

  bucket = each.value.documents

  tags = {
    Name = each.value.documents
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  for_each = local.names

  bucket = aws_s3_bucket.documents[each.key].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  for_each = local.names

  bucket = aws_s3_bucket.documents[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 문서를 덮어써 버린 것을 되돌릴 수 있게 합니다. 벡터는 재수집으로 복구되지만 원문은
# 그렇지 않습니다.
resource "aws_s3_bucket_versioning" "documents" {
  for_each = local.names

  bucket = aws_s3_bucket.documents[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  for_each = local.names

  bucket = aws_s3_bucket.documents[each.key].id

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

  rule {
    id     = "noncurrent-versions-90d"
    status = "Enabled"
    filter {
      prefix = ""
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
