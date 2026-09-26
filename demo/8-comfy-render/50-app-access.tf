# IAM — 앱과 워커가 사용하는 공유 정책

data "aws_iam_policy_document" "app_access" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
    ]
    resources = [
      aws_dynamodb_table.this.arn,
      "${aws_dynamodb_table.this.arn}/index/GSI1",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.static.arn}/*"]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketCors",
    ]
    resources = [aws_s3_bucket.static.arn]
  }

  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:PurgeQueue",
    ]
    resources = [aws_sqs_queue.render.arn]
  }
}

resource "aws_iam_policy" "app_access" {
  name   = "comfy-render-dev-app-access"
  policy = data.aws_iam_policy_document.app_access.json
}
