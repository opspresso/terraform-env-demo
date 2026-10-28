# A separate bucket keeps Agent Knowledge's HEAD/ListBucket authorization inside its own
# source boundary. It does not change Studio's bucket or its objects.
resource "aws_s3_bucket" "sources" {
  bucket = "agent-knowledge-static"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "sources" {
  bucket                  = aws_s3_bucket.sources.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sources" {
  bucket = aws_s3_bucket.sources.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled       = false
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_policy" "sources" {
  bucket = aws_s3_bucket.sources.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.sources.arn, "${aws_s3_bucket.sources.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.sources]
}

resource "aws_s3_bucket_lifecycle_configuration" "sources" {
  bucket = aws_s3_bucket.sources.id
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
