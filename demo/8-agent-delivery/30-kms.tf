# Agent Delivery가 SSM SecureString으로 저장하는 테넌트 Variable 전용 키입니다.
# SSM을 거친 요청만 허용하며, Agent Delivery와 테넌트 읽기 역할의 IAM 정책이 alias로 이 키를 선택합니다.
resource "aws_kms_key" "variables" {
  description             = "Agent Delivery tenant variables"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "variables" {
  name          = "alias/agent-delivery"
  target_key_id = aws_kms_key.variables.key_id
}
