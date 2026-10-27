# ECR — 앱 이미지

# 각 앱 저장소의 릴리스 파이프라인이 이미지를 밀어 넣습니다. k3s 호스트는 이 저장소들에서만
# 이미지를 끌어갑니다 (85-k3s-iam.tf 의 pull 정책).
#
# `keep_releases` 가 있는 저장소에만 lifecycle 규칙이 붙습니다. 규칙은 `release_tag_prefixes`
# 의 접두어마다 하나씩 만들고, 접두어별로 최근 `keep_releases` 개를 남깁니다. ECR 의
# `v*` 는 `sandbox-v*` 와 맞지 않으므로 Forge Sandbox 이미지는 따로 적어야 합니다.
#
# **"태그 없는 이미지를 만료시킨다" 는 규칙은 쓰지 마세요.** BuildKit 이 provenance
# attestation 을 붙이던 동안에는 태그가 가리키는 것이 바로 그 태그 없는 매니페스트였고,
# 그 뻔한 규칙이 릴리스된 태그를 깨뜨립니다 (agent-studio 저장소 docs/OPERATIONS.md).
locals {
  # 30 인 것은 릴리스 빈도 때문입니다 — 하루 네댓 번 나가므로 10 은 사흘치 롤백 창밖에
  # 되지 않습니다.
  ecr_repositories = {
    "agent-broker" = { keep_releases = 30, release_tag_prefixes = ["v"] }
    "agent-forge"  = { keep_releases = 30, release_tag_prefixes = ["v", "sandbox-v"] }
    "agent-librio" = { keep_releases = 30, release_tag_prefixes = ["v"] }
    "agent-memory" = { keep_releases = 30, release_tag_prefixes = ["v"] }
    "agent-models" = { keep_releases = 30, release_tag_prefixes = ["v"] }
    "agent-studio" = { keep_releases = 30, release_tag_prefixes = ["v"] }
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
      for index, prefix in each.value.release_tag_prefixes : {
        rulePriority = index + 1
        description  = "Keep the ${each.value.keep_releases} most recent ${prefix}* tags"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["${prefix}*"]
          countType      = "imageCountMoreThan"
          countNumber    = each.value.keep_releases
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
