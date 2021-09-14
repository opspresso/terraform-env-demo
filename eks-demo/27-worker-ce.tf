resource "aws_iam_policy" "worker-ce" {
  name        = format("%s-ce", local.cluster_name)
  description = format("GetCostAndUsage for %s", local.cluster_name)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ce:GetCostAndUsage",
        ]
        Resource = "*",
      },
    ]
  })
}
