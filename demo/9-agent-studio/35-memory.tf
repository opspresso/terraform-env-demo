# S3 — mcp-memory 의 상태 버킷 (STATE_BUCKET)

# 앱이 아니라 mcp-memory 서버가 씁니다. 여기 두는 이유는 이름이 같은 규칙을 따르고
# 환경마다 한 벌씩 필요하기 때문입니다 — 벡터는 같은 벡터 버킷의 `memories` 인덱스에
# 들어가고, 그 옆의 index/ 와 stats/ 가 이 버킷입니다.
resource "aws_s3_bucket" "memory" {
  for_each = local.names

  bucket = each.value.memory

  tags = {
    Name = each.value.memory
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 기억은 어느 경로로도 공개되지 않습니다.
resource "aws_s3_bucket_public_access_block" "memory" {
  for_each = local.names

  bucket = aws_s3_bucket.memory[each.key].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "memory" {
  for_each = local.names

  bucket = aws_s3_bucket.memory[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled       = false
    blocked_encryption_types = ["SSE-C"]
  }
}
