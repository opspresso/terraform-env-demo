# IDC 호스트 — 클러스터 밖에서 도는 두 번째 인스턴스

# 같은 테이블·버킷·인덱스를 읽는 같은 시스템이고, 다른 것은 자격증명을 얻는 방법뿐입니다.
# pod identity 가 없으므로 IAM 사용자 하나가 그 자리를 대신합니다.
# 배포 자체는 agent-studio 저장소의 deploy/idc/README.md 가 설명합니다.
resource "aws_iam_user" "idc" {
  name = "agent-studio"

  tags = {
    Name = "agent-studio"
  }

  # 액세스 키가 붙어 있는 사용자입니다. 지우는 계획은 여기서 멈춰야 합니다.
  lifecycle {
    prevent_destroy = true
  }
}

# 앱과 MCP 서버가 쓰는 권한은 `pod-role--*` 정책을 **그대로 재사용**합니다. 역할은 pod
# identity 전용이라 사용자에게 붙일 수 없지만, 정책은 4-role 이 `policies/*.json` 하나당
# 하나씩 만들어 두므로 역할과 무관하게 붙습니다. 덕분에 권한의 단일 소스가 유지됩니다 —
# 여기만 넓히려고 그 JSON 을 고치면 EKS 쪽도 함께 넓어진다는 뜻이기도 합니다.
locals {
  idc_shared_policies = [
    "pod-role--agent-studio",   # 앱
    "pod-role--mcp-memory",     # mcp-memory
    "pod-role--mcp-cloudwatch", # mcp-cloudwatch
  ]
}

resource "aws_iam_user_policy_attachment" "idc_shared" {
  for_each = toset(local.idc_shared_policies)

  user = aws_iam_user.idc.name
  # 4-role 이 이름을 결정적으로 짓기 때문에 ARN 을 조립할 수 있습니다. 그 모듈의 출력은
  # 역할 이름만 내보내므로 remote state 로는 정책 ARN 에 닿지 못합니다.
  policy_arn = format("arn:aws:iam::%s:policy/%s", local.account_id, each.value)
}

# 이미지를 끌어오는 권한만은 IDC 의 것입니다 — 클러스터는 노드 역할로 pull 합니다.
data "aws_iam_policy_document" "idc_ecr_pull" {
  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPullPrivateImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
    ]
    resources = [
      format("arn:aws:ecr:%s:%s:repository/agent-studio", var.region, local.account_id),
      format("arn:aws:ecr:%s:%s:repository/mcp-*", var.region, local.account_id),
    ]
  }
}

resource "aws_iam_policy" "idc_ecr_pull" {
  name        = "agent-studio-idc-ecr-pull"
  description = "ECR pull for the IDC alpha host (deploy/idc)"
  policy      = data.aws_iam_policy_document.idc_ecr_pull.json

  tags = {
    Name = "agent-studio-idc-ecr-pull"
  }
}

resource "aws_iam_user_policy_attachment" "idc_ecr_pull" {
  user       = aws_iam_user.idc.name
  policy_arn = aws_iam_policy.idc_ecr_pull.arn
}

# 호스트가 스스로 시크릿을 갱신할 수 있게 합니다 — `scripts/deploy.sh` 가 `fetch-env.sh` 를
# 부르고, 그것이 이 권한으로 SSM 을 읽습니다.
#
# **이것은 트레이드오프다.** 이 키가 유출되면 배포 시크릿 전부가 함께 열린다 — 앱의 것과
# MCP 서버들의 것. 그 대신 호스트가 노트북의 SSO 자격증명 없이 최신 시크릿으로 배포할 수
# 있다. 경로를 `/k8s/common/agent-studio/*` 와 `/k8s/common/mcp-*` 로 좁혀 두는 것이 그 폭을
# 줄이는 유일한 수단이다. Agent Memory도 같은 호스트에서 별도 application으로 실행되므로
# 자기 namespace만 추가한다.
data "aws_iam_policy_document" "idc_ssm_read" {
  statement {
    sid    = "ReadDeploymentParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      format("arn:aws:ssm:%s:%s:parameter/k8s/common/agent-studio/*", var.region, local.account_id),
      format("arn:aws:ssm:%s:%s:parameter/k8s/common/agent-memory/*", var.region, local.account_id),
      format("arn:aws:ssm:%s:%s:parameter/k8s/common/mcp-*", var.region, local.account_id),
    ]
  }

  # SecureString 은 SSM 을 통해서만 풀립니다. 조건 없이 주면 이 키가 계정의 다른 KMS 사용처까지
  # 여는 것이 되므로, `kms:ViaService` 로 SSM 경유만 허용합니다.
  statement {
    sid       = "DecryptSecureStrings"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [format("ssm.%s.amazonaws.com", var.region)]
    }
  }
}

resource "aws_iam_policy" "idc_ssm_read" {
  name        = "agent-studio-idc-ssm-read"
  description = "Deployment parameters for the IDC alpha host (deploy/idc)"
  policy      = data.aws_iam_policy_document.idc_ssm_read.json

  tags = {
    Name = "agent-studio-idc-ssm-read"
  }
}

resource "aws_iam_user_policy_attachment" "idc_ssm_read" {
  user       = aws_iam_user.idc.name
  policy_arn = aws_iam_policy.idc_ssm_read.arn
}

# 액세스 키는 여기서 만들지 않습니다. terraform 이 만들면 비밀키가 state 에 평문으로
# 남습니다 — 그 state 는 `deploy/idc/.env.aws` 보다 넓게 읽힙니다. 키 발급과 회전은
# 사람이 `aws iam create-access-key` 로 합니다.

# IDC 호스트를 가리키는 이름. 3-alb 의 레코드들은 ALB alias 라 그 모듈의 두 리소스에
# 맞지 않습니다 — 이것은 물리 호스트의 IP 하나입니다.
data "aws_route53_zone" "root" {
  name         = "opspresso.com"
  private_zone = false
}

resource "aws_route53_record" "idc" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = "studio.opspresso.com"
  type    = "A"
  ttl     = 300
  records = [var.idc_host_ip]
}

resource "aws_route53_record" "idc_memory" {
  zone_id         = data.aws_route53_zone.root.zone_id
  name            = "memory.opspresso.com"
  type            = "A"
  ttl             = 300
  records         = [var.idc_host_ip]
  allow_overwrite = true
}
