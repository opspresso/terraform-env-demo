# S3 — mcp-memory v0.8 이전 상태 보존 버킷

# mcp-memory v0.9부터 PostgreSQL만 사용하므로 런타임은 이 버킷에 접근하지 않습니다.
# 이전 버전의 데이터를 보존하고 기존 Terraform state가 삭제를 계획하지 않도록 계속
# 관리합니다. 보존 기한과 폐기를 별도로 결정하기 전에는 이 리소스를 제거하지 않습니다.
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
