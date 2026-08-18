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

# 편입하지 않는 것 — 같은 벡터 버킷 안에 있지만 이 모듈의 것이 아닙니다:
#   agent-studio-vector/memories          mcp-memory 저장소가 소유합니다
#   agent-studio-vector/capabilities-local 로컬 개발이 쓰는 인덱스
# 버킷은 이 모듈이 갖되 남의 인덱스는 건드리지 않습니다. 버킷에 걸린 prevent_destroy 는
# 그 둘도 함께 지킵니다.
