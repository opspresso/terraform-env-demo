# 배포된 테넌트 앱(namespace `app-<project>-<env>`, SA `app`)의 Pod Identity 역할입니다.
# Agent Runway가 `s3-bucket`·`dynamodb` 리소스가 있는 namespace에만 association을 만듭니다.
# Pod Identity session tag로 자기 namespace의 리소스만 허용하므로 역할 하나를 모든 테넌트가 공유합니다.
resource "aws_iam_role" "runway_tenant_objects" {
  name = "agent-runway-tenant-objects"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnEquals    = { "aws:SourceArn" = "arn:aws:eks:${var.region}:${local.account_id}:cluster/${var.cluster_name}" }
      }
    }]
  })
}

resource "aws_iam_role_policy" "runway_tenant_objects" {
  name = "objects"
  role = aws_iam_role.runway_tenant_objects.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Dedicated buckets of kro S3Bucket (argocd-env-addons charts/kro): <cluster>-<hash>, tagged with the cluster and
      # the instance namespace, with ABAC on. The name alone does not identify the namespace, so the bucket tags decide.
      # Only kro and the ACK S3 controller set those tags; tenants cannot create Bucket objects or tag buckets.
      {
        Sid      = "OwnNamespaceBuckets"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:ListBucketVersions", "s3:ListBucketMultipartUploads", "s3:GetBucketLocation"]
        Resource = "arn:aws:s3:::$${aws:PrincipalTag/eks-cluster-name}-*"
        Condition = {
          StringEquals = {
            # A bucket of the same name in another account (bucket names are global) never matches.
            "aws:ResourceAccount"                  = local.account_id
            "aws:ResourceTag/eks-cluster-name"     = "$${aws:PrincipalTag/eks-cluster-name}"
            "aws:ResourceTag/kubernetes-namespace" = "$${aws:PrincipalTag/kubernetes-namespace}"
          }
          Bool = { "aws:SecureTransport" = "true" }
        }
      },
      {
        Sid    = "OwnNamespaceBucketObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion",
          "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts",
        ]
        Resource = "arn:aws:s3:::$${aws:PrincipalTag/eks-cluster-name}-*/*"
        Condition = {
          StringEquals = {
            # A bucket of the same name in another account (bucket names are global) never matches.
            "aws:ResourceAccount"                  = local.account_id
            "aws:ResourceTag/eks-cluster-name"     = "$${aws:PrincipalTag/eks-cluster-name}"
            "aws:ResourceTag/kubernetes-namespace" = "$${aws:PrincipalTag/kubernetes-namespace}"
          }
          Bool = { "aws:SecureTransport" = "true" }
        }
      },
      # Dedicated tables of kro DynamoTable (argocd-env-addons charts/kro): app-<hash>, tagged like the buckets above.
      # Only kro and the ACK DynamoDB controller set those tags; tenants cannot create Table objects or tag tables.
      {
        Sid    = "OwnNamespaceTables"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable", "dynamodb:GetItem", "dynamodb:BatchGetItem", "dynamodb:Query", "dynamodb:Scan",
          "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:BatchWriteItem", "dynamodb:ConditionCheckItem",
        ]
        Resource = "arn:aws:dynamodb:${var.region}:${local.account_id}:table/app-*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/eks-cluster-name"     = "$${aws:PrincipalTag/eks-cluster-name}"
            "aws:ResourceTag/kubernetes-namespace" = "$${aws:PrincipalTag/kubernetes-namespace}"
          }
        }
      },
    ]
  })
}
