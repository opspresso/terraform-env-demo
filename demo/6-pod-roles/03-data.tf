# data

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
  }
}
