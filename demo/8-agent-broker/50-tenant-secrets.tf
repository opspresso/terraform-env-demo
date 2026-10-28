# 테넌트 namespace의 SecretStore가 External Secrets 역할에서 assume하는 읽기 역할입니다.
# SecretStore가 session tag `broker-project`·`broker-env`를 붙이고, 이 정책은 그 tag의 경로만 허용합니다.
# 따라서 다른 Project의 경로를 참조한 ExternalSecret은 AWS에서 거부됩니다.
resource "aws_iam_role" "tenant_secrets" {
  name = "agent-broker-tenant-secrets"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = local.external_secrets_role_arn }
        Action    = "sts:AssumeRole"
        Condition = {
          StringLike = {
            "aws:RequestTag/broker-project" = "?*"
            "aws:RequestTag/broker-env"     = ["dev", "prod"]
          }
        }
      },
      {
        Effect    = "Allow"
        Principal = { AWS = local.external_secrets_role_arn }
        Action    = "sts:TagSession"
        # EKS Pod Identity session tags are transitive, so a chained session carries them as well.
        Condition = {
          "ForAllValues:StringEquals" = { "aws:TagKeys" = concat(["broker-project", "broker-env"], local.pod_identity_tag_keys) }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "tenant_secrets" {
  name = "variables"
  role = aws_iam_role.tenant_secrets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OwnEnvironmentVariables"
        Effect = "Allow"
        Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = [
          "arn:aws:ssm:${var.region}:${local.account_id}:parameter/agent-broker/${var.cluster_name}/$${aws:PrincipalTag/broker-project}/$${aws:PrincipalTag/broker-env}",
          "arn:aws:ssm:${var.region}:${local.account_id}:parameter/agent-broker/${var.cluster_name}/$${aws:PrincipalTag/broker-project}/$${aws:PrincipalTag/broker-env}/*",
        ]
      },
      {
        Sid      = "DecryptVariables"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.variables.arn
        Condition = {
          StringEquals = { "kms:ViaService" = "ssm.${var.region}.amazonaws.com" }
        }
      },
    ]
  })
}
