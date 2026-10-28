# Delivery build 단계가 이미지를 push할 때 쓰는 역할입니다.
# registry 단계가 session tag `delivery-project`를 붙여 assume하고, 이 정책은 그 Project의 repository만 허용합니다.
# 그래서 build 단계의 앱 코드가 push credential을 읽어도 다른 Project의 이미지는 바꿀 수 없습니다.
resource "aws_iam_role" "push" {
  name                 = "app-delivery-push"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = local.registry_role_arn }
        Action    = "sts:AssumeRole"
        Condition = {
          StringLike = { "aws:RequestTag/delivery-project" = "?*" }
        }
      },
      {
        Effect    = "Allow"
        Principal = { AWS = local.registry_role_arn }
        Action    = "sts:TagSession"
        # EKS Pod Identity session tags are transitive, so a chained session carries them as well.
        Condition = {
          "ForAllValues:StringEquals" = { "aws:TagKeys" = concat(["delivery-project"], local.pod_identity_tag_keys) }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "push" {
  name = "project-repository"
  role = aws_iam_role.push.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "RegistryLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "OwnProjectRepository"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = "arn:aws:ecr:${var.region}:${local.account_id}:repository/projects/$${aws:PrincipalTag/delivery-project}"
      },
    ]
  })
}
