# k3s 노드가 공통 애플리케이션을 실행할 때 사용하는 정책

data "aws_iam_policy_document" "k3s_ecr_pull" {
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
      format("arn:aws:ecr:%s:%s:repository/agent-memory", var.region, local.account_id),
      format("arn:aws:ecr:%s:%s:repository/agent-studio", var.region, local.account_id),
      format("arn:aws:ecr:%s:%s:repository/mcp-*", var.region, local.account_id),
    ]
  }
}

resource "aws_iam_policy" "k3s_ecr_pull" {
  name        = "agent-studio-k3s-ecr-pull"
  description = "ECR pull for the k3s node"
  policy      = data.aws_iam_policy_document.k3s_ecr_pull.json

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "agent-studio-k3s-ecr-pull"
  }
}

data "aws_iam_policy_document" "k3s_ssm_read" {
  statement {
    sid    = "ReadDeploymentParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      format("arn:aws:ssm:%s:%s:parameter/k8s/common/*", var.region, local.account_id),
    ]
  }

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

resource "aws_iam_policy" "k3s_ssm_read" {
  name        = "agent-studio-k3s-ssm-read"
  description = "Deployment parameters for the k3s node"
  policy      = data.aws_iam_policy_document.k3s_ssm_read.json

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "agent-studio-k3s-ssm-read"
  }
}
