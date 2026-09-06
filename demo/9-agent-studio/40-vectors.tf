# S3 Vectors — 케이퍼빌리티 카탈로그와 Knowledge Base 의 벡터 저장소

resource "aws_s3vectors_vector_bucket" "this" {
  for_each = local.names

  vector_bucket_name = each.value.vector

  encryption_configuration {
    sse_type = "AES256"
  }

  tags = {
    Name = each.value.vector
  }

  # `force_destroy` 는 기본값 false 로 둡니다 — true 였다면 버킷을 지우는 계획 하나가
  # 안에 있는 모든 인덱스와 벡터를 함께 가져갑니다.
  lifecycle {
    prevent_destroy = true
  }
}

# 카탈로그와 Knowledge Base 인덱스에는 `prevent_destroy` 를 걸지 않습니다. 안에 든 것은
# 파생 데이터고 — 카탈로그는 CronJob 틱이, KB 는 재수집이 다시 채웁니다 — 차원이나 거리
# 함수를 바꾸는 정당한 변경이 replace 로 나타나기 때문입니다. 아래의 이전 Memory 인덱스는
# 원본 데이터 보존 대상이라 예외입니다.

# 앱이 자기 케이퍼빌리티(스킬·MCP 도구·에이전트)를 검색하는 인덱스. CronJob 틱이
# 다시 만들고, 런은 읽기만 합니다.
resource "aws_s3vectors_index" "catalog" {
  for_each = local.names

  vector_bucket_name = aws_s3vectors_vector_bucket.this[each.key].vector_bucket_name
  index_name         = local.catalog_index

  data_type       = "float32"
  dimension       = var.embedding_dimension
  distance_metric = "cosine"

  # 설명문은 검색 결과와 함께 돌려받을 뿐 필터에 쓰지 않습니다.
  metadata_configuration {
    non_filterable_metadata_keys = ["description"]
  }

  encryption_configuration {
    sse_type = "AES256"
  }
}

# Knowledge Base 전용. 카탈로그와 같은 인덱스를 쓸 수 없는 이유는 두 가지입니다:
# Bedrock 이 청크 본문과 자기 메타데이터를 non-filterable 키로 요구하고, AWS 가 KB 마다
# 벡터 스토어를 나누라고 권합니다.
resource "aws_s3vectors_index" "knowledge" {
  for_each = local.names

  vector_bucket_name = aws_s3vectors_vector_bucket.this[each.key].vector_bucket_name
  index_name         = local.knowledge_index

  data_type       = "float32"
  dimension       = var.embedding_dimension
  distance_metric = "cosine"

  metadata_configuration {
    non_filterable_metadata_keys = local.bedrock_metadata_keys
  }

  encryption_configuration {
    sse_type = "AES256"
  }
}

# mcp-memory v0.8 이전 데이터 보존 인덱스. v0.9부터 서버는 PostgreSQL만 사용하며 이
# 인덱스에 접근하지 않습니다. 기존 데이터를 보존하고 Terraform이 삭제를 계획하지 않도록
# 계속 관리합니다. 보존 기한과 폐기를 별도로 결정하기 전에는 이 리소스를 제거하지 않습니다.
resource "aws_s3vectors_index" "memories" {
  for_each = local.names

  vector_bucket_name = aws_s3vectors_vector_bucket.this[each.key].vector_bucket_name
  index_name         = "memories"

  data_type = "float32"
  # 기존 Titan(`amazon.titan-embed-text-v2:0`) 데이터의 차원을 유지합니다.
  dimension       = var.embedding_dimension
  distance_metric = "cosine"

  metadata_configuration {
    non_filterable_metadata_keys = ["content", "createdAt", "tags", "trustBase"]
  }

  encryption_configuration {
    sse_type = "AES256"
  }

  lifecycle {
    prevent_destroy = true
  }
}
