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

  # 인덱스의 키는 `key_schema` 로 씁니다 — GSI 블록의 `hash_key`/`range_key` 는 provider
  # 6.55 에서 deprecated 이고, 그 경고는 블록이 아니라 리소스 첫 줄에 붙어 표시되므로
  # 테이블 자신의 키가 문제인 것처럼 읽힙니다. 최상위 `hash_key`/`range_key` 는 그대로입니다.
  global_secondary_index {
    name            = "GSI1"
    projection_type = "ALL"

    key_schema {
      attribute_name = "GSI1PK"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "GSI1SK"
      key_type       = "RANGE"
    }
  }

  global_secondary_index {
    name            = "GSI2"
    projection_type = "ALL"

    key_schema {
      attribute_name = "GSI2PK"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "GSI2SK"
      key_type       = "RANGE"
    }
  }

  # 만료되는 행 — 트레이스, 트랜스크립트, 클레임 — 이 스스로 사라지는 자리.
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  # 아래 `prevent_destroy` 는 terraform 이 지우는 것만 막습니다. 콘솔과 CLI 는 그것을 모르고,
  # 이 테이블 하나가 프로젝트·버전·chat·usage·트레이스·레지스트리·세션 전부입니다.
  deletion_protection_enabled = true

  # 실수로 덮어쓴 행을 되돌릴 수 있는 유일한 수단입니다. 테이블이 2MB 남짓이라 비용은
  # 사실상 없고, TTL 로 사라진 행까지 복구창 안에서는 되살아납니다.
  point_in_time_recovery {
    enabled = true
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
