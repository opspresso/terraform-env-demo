# GitHub Actions — 릴리스가 ECR 로 푸시할 때 빌리는 신원

# 장기 키가 없습니다. 워크플로가 OIDC 토큰으로 이 역할을 assume 합니다
# (agentdure 저장소의 .github/workflows/release.yml).
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

    # 실물 그대로입니다. 숫자가 붙은 형태는 GitHub 이 owner·repo 를 id 로 고정해 발급하는
    # subject 이고, 리브랜딩 전 `agent-studio` 이름의 항목도 아직 남아 있습니다. 정리는
    # 릴리스가 실제로 어느 형태를 보내는지 확인한 뒤에 할 일입니다 — 여기서 지우면 다음
    # 태그 푸시가 assume 에 실패합니다.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:opspresso@38965494/agentdure@1307383317:ref:refs/tags/v*",
        "repo:opspresso@38965494/agentdure@1307383317:ref:refs/heads/main",
        "repo:opspresso@38965494/agent-studio@1307383317:ref:refs/tags/v*",
        "repo:opspresso@38965494/agent-studio@1307383317:ref:refs/heads/main",
        "repo:opspresso/agentdure:ref:refs/tags/v*",
        "repo:opspresso/agentdure:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "github_ecr" {
  name               = "github--agentdure-ecr"
  description        = "agentdure ECR push from GitHub Actions OIDC"
  assume_role_policy = data.aws_iam_policy_document.github_ecr_assume.json

  tags = {
    Name = "github--agentdure-ecr"
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
    # 저장소 리소스의 `.arn` 대신 조립합니다. 그 저장소는 이 계획에서 import 되는 중이라
    # 값이 apply 전에는 알려지지 않고, 그러면 이 정책 전체가 "known after apply" 로 보여
    # 편입이 무변경인지 계획만으로 확인할 수 없게 됩니다.
    resources = [format("arn:aws:ecr:%s:%s:repository/agentdure", var.region, local.account_id)]
  }
}

resource "aws_iam_role_policy" "github_ecr" {
  name   = "ecr-push-agentdure"
  role   = aws_iam_role.github_ecr.id
  policy = data.aws_iam_policy_document.github_ecr.json
}
