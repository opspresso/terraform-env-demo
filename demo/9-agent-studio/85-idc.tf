# IDC 호스트용 legacy IAM — k3s 전환이 안정화될 때까지 유지한다.

resource "aws_iam_user" "idc" {
  name = "agent-studio"

  tags = {
    Name = "agent-studio"
  }

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  idc_shared_policies = [
    "pod-role--agent-studio",
    "pod-role--mcp-memory",
    "pod-role--mcp-cloudwatch",
  ]
}

resource "aws_iam_user_policy_attachment" "idc_shared" {
  for_each = toset(local.idc_shared_policies)

  user       = aws_iam_user.idc.name
  policy_arn = format("arn:aws:iam::%s:policy/%s", local.account_id, each.value)
}

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
      format("arn:aws:ecr:%s:%s:repository/agent-memory", var.region, local.account_id),
      format("arn:aws:ecr:%s:%s:repository/agent-studio", var.region, local.account_id),
      format("arn:aws:ecr:%s:%s:repository/mcp-*", var.region, local.account_id),
    ]
  }
}

resource "aws_iam_policy" "idc_ecr_pull" {
  name        = "agent-studio-idc-ecr-pull"
  description = "ECR pull for the legacy IDC alpha host (deploy/idc)"
  policy      = data.aws_iam_policy_document.idc_ecr_pull.json

  tags = {
    Name = "agent-studio-idc-ecr-pull"
  }
}

resource "aws_iam_user_policy_attachment" "idc_ecr_pull" {
  user       = aws_iam_user.idc.name
  policy_arn = aws_iam_policy.idc_ecr_pull.arn
}

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

resource "aws_iam_policy" "idc_ssm_read" {
  name        = "agent-studio-idc-ssm-read"
  description = "Deployment parameters for the legacy IDC alpha host (deploy/idc)"
  policy      = data.aws_iam_policy_document.idc_ssm_read.json

  tags = {
    Name = "agent-studio-idc-ssm-read"
  }
}

resource "aws_iam_user_policy_attachment" "idc_ssm_read" {
  user       = aws_iam_user.idc.name
  policy_arn = aws_iam_policy.idc_ssm_read.arn
}
