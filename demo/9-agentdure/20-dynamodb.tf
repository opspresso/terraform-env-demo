# DynamoDB — 앱의 단일 테이블

# 스키마는 앱이 정합니다: PK/SK 위에 GSI1·GSI2 두 개, TTL 은 `expiresAt`.
# 자세한 키 맵은 agentdure 저장소의 docs/ARCHITECTURE.md 를 보세요.
resource "aws_dynamodb_table" "this" {
  for_each = local.names

  name         = each.value.table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  dynamic "attribute" {
    for_each = ["PK", "SK", "GSI1PK", "GSI1SK", "GSI2PK", "GSI2SK"]
    content {
      name = attribute.value
      type = "S"
    }
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GSI2"
    hash_key        = "GSI2PK"
    range_key       = "GSI2SK"
    projection_type = "ALL"
  }

  # 만료되는 행 — 트레이스, 트랜스크립트, 클레임 — 이 스스로 사라지는 자리.
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Name = each.value.table
  }

  # 이 테이블이 곧 서비스의 전부입니다. 이름을 바꾸는 변경은 replace 로 나타나므로,
  # 그런 계획은 apply 되기 전에 여기서 멈춰야 합니다.
  lifecycle {
    prevent_destroy = true
  }
}
