# import — 손으로 만들어져 이미 서비스 중인 리소스를 상태로 편입합니다.
#
# **plan 이 이 대상들에 대해 "no changes" 인 것을 확인한 뒤에만 apply 하세요.** update 나
# replace 가 하나라도 뜨면 코드가 실물과 다른 것이고, 그때 고칠 것은 실물이 아니라 코드
# 입니다 — 여기 든 테이블 두 개에는 서비스 데이터가 들어 있습니다.
#
# 첫 apply 가 끝나면 이 파일은 지워도 됩니다. 편입은 한 번만 일어납니다.

import {
  to = aws_dynamodb_table.this["prod"]
  id = "agentdure"
}

import {
  to = aws_dynamodb_table.this["alpha"]
  id = "agent-studio"
}

import {
  to = aws_s3_bucket.static["prod"]
  id = "agentdure-static"
}

import {
  to = aws_s3_bucket_public_access_block.static["prod"]
  id = "agentdure-static"
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.static["prod"]
  id = "agentdure-static"
}

import {
  to = aws_s3_bucket_policy.static["prod"]
  id = "agentdure-static"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.static["prod"]
  id = "agentdure-static"
}

import {
  to = aws_s3_bucket.memory["alpha"]
  id = "agent-studio-memory"
}

import {
  to = aws_s3_bucket_public_access_block.memory["alpha"]
  id = "agent-studio-memory"
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.memory["alpha"]
  id = "agent-studio-memory"
}

# 계정 번호는 backend 설정과 같은 이유로 문자열입니다 — import 는 plan 이전에 풀려야
# 하는 값이라 조회에 기대지 않습니다.
import {
  to = aws_s3vectors_vector_bucket.this["alpha"]
  id = "arn:aws:s3vectors:ap-northeast-2:396608815058:bucket/agent-studio-vector"
}

import {
  to = aws_s3vectors_index.catalog["alpha"]
  id = "arn:aws:s3vectors:ap-northeast-2:396608815058:bucket/agent-studio-vector/index/capabilities"
}

# IDC — 손으로 만든 사용자와 정책, 그리고 호스트를 가리키는 레코드.
import {
  to = aws_iam_user.idc
  id = "agentdure"
}

import {
  to = aws_iam_policy.idc_ecr_pull
  id = "arn:aws:iam::396608815058:policy/agentdure-idc-ecr-pull"
}

import {
  to = aws_iam_user_policy_attachment.idc_ecr_pull
  id = "agentdure/arn:aws:iam::396608815058:policy/agentdure-idc-ecr-pull"
}

import {
  for_each = toset(local.idc_shared_policies)

  to = aws_iam_user_policy_attachment.idc_shared[each.value]
  id = "agentdure/arn:aws:iam::396608815058:policy/${each.value}"
}

import {
  to = aws_route53_record.idc
  id = "${data.aws_route53_zone.root.zone_id}_alpha.agentdure.com_A"
}

# ECR — 네 저장소와, 지금 유일하게 lifecycle 규칙을 가진 하나.
import {
  for_each = local.ecr_repositories

  to = aws_ecr_repository.this[each.key]
  id = each.key
}

import {
  to = aws_ecr_lifecycle_policy.this["mcp-document"]
  id = "mcp-document"
}

# 릴리스가 빌리는 GitHub OIDC 역할.
import {
  to = aws_iam_role.github_ecr
  id = "github--agentdure-ecr"
}

import {
  to = aws_iam_role_policy.github_ecr
  id = "github--agentdure-ecr:ecr-push-agentdure"
}

import {
  to = aws_s3vectors_index.memories["alpha"]
  id = "arn:aws:s3vectors:ap-northeast-2:396608815058:bucket/agent-studio-vector/index/memories"
}

# 편입하지 않는 것 — 같은 벡터 버킷 안에 있지만 이 모듈의 것이 아닙니다:
#   agent-studio-vector/capabilities-local 로컬 개발이 쓰는 인덱스
# 버킷에 걸린 prevent_destroy 가 그것도 함께 지킵니다.
