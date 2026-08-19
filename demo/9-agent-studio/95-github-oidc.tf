# GitHub Actions — 릴리스가 ECR 로 푸시할 때 빌리는 신원

# 장기 키가 없습니다. 워크플로가 OIDC 토큰으로 이 역할을 assume 합니다
# (agent-studio 저장소의 .github/workflows/release.yml).
data "aws_iam_policy_document" "github_ecr_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        format("arn:aws:iam::%s:oidc-provider/token.actions.githubusercontent.com", local.account_id),
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # 두 형태를 다 둡니다. 숫자가 붙은 형태는 GitHub 이 owner·repo 를 id 로 고정해 발급하는
    # subject 이고(저장소 id 1307383317 은 이름이 바뀌어도 같습니다), 숫자 없는 형태는
    # 기본 subject 입니다. 어느 쪽이 오는지는 릴리스 로그로 확인한 뒤 정리합니다 — 여기서
    # 잘못 지우면 다음 태그 푸시가 assume 에 실패합니다.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:opspresso@38965494/agent-studio@1307383317:ref:refs/tags/v*",
        "repo:opspresso@38965494/agent-studio@1307383317:ref:refs/heads/main",
        "repo:opspresso/agent-studio:ref:refs/tags/v*",
        "repo:opspresso/agent-studio:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "github_ecr" {
  name               = "github--agent-studio-ecr"
  description        = "agent-studio ECR push from GitHub Actions OIDC"
  assume_role_policy = data.aws_iam_policy_document.github_ecr_assume.json

  tags = {
    Name = "github--agent-studio-ecr"
  }
}

# 푸시에 필요한 것만입니다 — 저장소 하나, 삭제 권한 없음.
data "aws_iam_policy_document" "github_ecr" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    # 저장소 리소스의 `.arn` 대신 조립합니다. 저장소가 같은 계획에서 만들어지면 그 값은
    # apply 전에는 알려지지 않고, 그러면 이 정책 전체가 "known after apply" 로 보여
    # 계획만으로 무엇이 바뀌는지 읽을 수 없게 됩니다.
    resources = [format("arn:aws:ecr:%s:%s:repository/agent-studio", var.region, local.account_id)]
  }
}

resource "aws_iam_role_policy" "github_ecr" {
  name   = "ecr-push-agent-studio"
  role   = aws_iam_role.github_ecr.id
  policy = data.aws_iam_policy_document.github_ecr.json
}

# GitHub Actions — 주간 모델 점검이 mantle 에 무엇이 서빙되는지 물을 때 빌리는 신원

# 신뢰 조건은 위와 같은 문서를 씁니다. 같은 저장소의 같은 ref 들이고, 조건을 한 번 더 적으면
# 둘이 갈라질 수 있습니다. 역할을 나누는 이유는 반대쪽입니다: 모델 목록을 읽는 워크플로가
# 이미지를 푸시할 수 있을 이유가 없습니다.
resource "aws_iam_role" "github_models" {
  name               = "github--agent-studio-models"
  description        = "agent-studio model registry check from GitHub Actions OIDC"
  assume_role_policy = data.aws_iam_policy_document.github_ecr_assume.json

  tags = {
    Name = "github--agent-studio-models"
  }
}

# 읽기 하나뿐입니다. `bedrock-mantle:ListModels` 는 mantle 의 OpenAI 호환 `/v1/models` 가
# CloudTrail 에 남기는 그 호출이고(리소스는 `project/default`), 파드가 디스패치에 쓰는
# `bedrock-mantle:CreateInference` 와 같은 계열입니다 — 이 역할에는 그쪽이 없습니다.
data "aws_iam_policy_document" "github_models" {
  statement {
    effect    = "Allow"
    actions   = ["bedrock-mantle:ListModels"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_models" {
  name   = "mantle-list-models"
  role   = aws_iam_role.github_models.id
  policy = data.aws_iam_policy_document.github_models.json
}
