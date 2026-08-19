# locals

locals {
  account_id = data.aws_caller_identity.current.account_id

  # 이름이 곧 환경입니다. 지금 있는 환경은 alpha 하나 — IDC 호스트가 읽는 `agent-studio`
  # 세트입니다. 나머지 리소스 이름은 전부 여기서 파생되므로, 환경을 하나 더 만드는 것은
  # 아래 맵에 줄 하나를 더하는 일입니다. production 은 `agent-studio-prod` 로 정해 두었지만
  # 아직 만들지 않습니다 — 주석을 풀면 테이블·버킷·인덱스·KB 한 벌이 그 이름으로 생깁니다.
  envs = {
    alpha = { base = "agent-studio" }
    # prod = { base = "agent-studio-prod" }
  }

  names = {
    for env, cfg in local.envs : env => {
      table     = cfg.base             # DYNAMODB_TABLE_NAME
      static    = "${cfg.base}-static" # S3_BUCKET_NAME — 아티팩트와 이미지
      vector    = "${cfg.base}-vector" # VECTOR_BUCKET — 케이퍼빌리티 카탈로그와 KB
      memory    = "${cfg.base}-memory" # STATE_BUCKET — mcp-memory 의 상태
      documents = "${cfg.base}-kb"     # Knowledge Base 가 읽어들일 문서 저장소
      knowledge = cfg.base             # Knowledge Base 이름
    }
  }

  # 앱이 자기 케이퍼빌리티 카탈로그를 두는 인덱스. `CATALOG_INDEX` 가 가리킵니다.
  catalog_index = "capabilities"

  # Knowledge Base 전용 인덱스. AWS 는 KB 마다 벡터 스토어를 나누라고 권하고, 무엇보다
  # 아래 두 메타데이터 키를 Bedrock 이 요구하므로 카탈로그 인덱스와 같이 쓸 수 없습니다.
  knowledge_index = "knowledge"

  # Bedrock 이 청크 본문과 자기 메타데이터를 넣는 자리. 필터에 걸리면 안 되므로
  # non-filterable 로 선언합니다.
  bedrock_metadata_keys = ["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"]

  tags = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/9-agent-studio"
  }
}
