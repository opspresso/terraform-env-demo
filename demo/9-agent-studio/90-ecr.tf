# ECR — 앱과 MCP 서버의 이미지

# `agent-studio` 는 릴리스 파이프라인이 밀어 넣고, `mcp-*` 는 각 서버 저장소가 밀어 넣습니다.
# IDC 호스트가 끌어가는 것도 이 넷입니다 (85-idc.tf 의 pull 정책).
#
# `keep_releases` 가 있는 저장소에만 lifecycle 규칙이 붙습니다 — 지금 실제로 가진 것은
# mcp-document 뿐이고, 나머지는 모든 이미지를 남깁니다.
#
# **"태그 없는 이미지를 만료시킨다" 는 규칙은 쓰지 마세요.** BuildKit 이 provenance
# attestation 을 붙이던 동안에는 태그가 가리키는 것이 바로 그 태그 없는 매니페스트였고,
# 그 뻔한 규칙이 릴리스된 태그를 깨뜨립니다 (agent-studio 저장소 docs/OPERATIONS.md).
locals {
  # `agent-studio` 만 30 인 것은 릴리스 빈도 때문입니다 — 하루 네댓 번 나가므로 10 은 사흘치
  # 롤백 창밖에 되지 않습니다. MCP 서버들은 드물게 나가서 10 이 몇 달을 덮습니다.
  ecr_repositories = {
    "agent-studio" = { keep_releases = 30 }
    "mcp-memory"   = { keep_releases = 10 }
    "mcp-document" = { keep_releases = 10 }
    "mcp-youtube"  = { keep_releases = 10 }
  }
}

resource "aws_ecr_repository" "this" {
  for_each = local.ecr_repositories

  name                 = each.key
  image_tag_mutability = "MUTABLE"

  # 기본 스캐닝은 무료이고 푸시를 막지도 않습니다. 켜 두지 않으면 취약점은 아무도 보지
  # 않는 곳에 남습니다.
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = each.key
  }

  # 안에 릴리스된 이미지가 들어 있습니다. `force_delete` 는 기본값 false 로 둡니다.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = { for name, cfg in local.ecr_repositories : name => cfg if cfg.keep_releases != null }

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the ${each.value.keep_releases} most recent release tags"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["v*"]
          countType      = "imageCountMoreThan"
          countNumber    = each.value.keep_releases
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}
