# sqs

locals {
  sqs_nth = format("%s-nth", var.name)
}

resource "aws_sqs_queue" "nth" {
  name = local.sqs_nth

  message_retention_seconds = 600

  policy = data.aws_iam_policy_document.sqs.json

  tags = merge(
    local.tags,
    {
      "Name" = local.sqs_nth
    },
  )
}

data "aws_iam_policy_document" "sqs" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
        "autoscaling.amazonaws.com",
      ]
    }
    actions = [
      "sqs:SendMessage",
    ]
    resources = [
      "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.sqs_nth}",
    ]
  }
}
