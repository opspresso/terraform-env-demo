# IAM — Amplify SSR compute role

data "aws_iam_policy_document" "amplify_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["amplify.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        format("arn:aws:amplify:%s:%s:apps/%s/*", var.region, local.account_id, local.amplify_app_id),
      ]
    }
  }
}

resource "aws_iam_role" "amplify_compute" {
  name               = "comfy-render-dev-amplify-compute"
  description        = "SSR compute role assumed by the Amplify-hosted app for DynamoDB/S3/SQS access."
  assume_role_policy = data.aws_iam_policy_document.amplify_assume.json

  tags = {
    Name = "comfy-render-dev-amplify-compute"
  }
}

resource "aws_iam_role_policy_attachment" "amplify_app_access" {
  role       = aws_iam_role.amplify_compute.name
  policy_arn = aws_iam_policy.app_access.arn
}
