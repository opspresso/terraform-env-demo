# data

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "pods.eks.amazonaws.com",
      ]
    }
    actions = [
      "sts:TagSession",
      "sts:AssumeRole",
    ]

    # 같은 계정의 EKS Pod Identity 만 이 역할을 맡을 수 있도록 제한합니다.
    # 클러스터 단위로 더 좁히려면 aws:SourceArn 에 클러스터 ARN 을 추가합니다.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
