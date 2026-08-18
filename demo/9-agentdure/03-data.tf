# data

data "aws_caller_identity" "current" {
}

# Knowledge Base 서비스 롤이 신뢰하는 쪽. 계정과 KB ARN 으로 좁혀, 남의 Bedrock 리소스가
# 이 롤을 빌릴 수 없게 합니다 (confused deputy).
data "aws_iam_policy_document" "knowledge_base_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        format("arn:aws:bedrock:%s:%s:knowledge-base/*", var.region, data.aws_caller_identity.current.account_id),
      ]
    }
  }
}
