# 테넌트 bucket 리소스가 공유하는 bucket입니다. 리소스마다 `<cluster>/app-<project>-<env>/<name>/` prefix를 씁니다.
resource "aws_s3_bucket" "objects" {
  bucket = "agent-delivery-objects"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "objects" {
  bucket                  = aws_s3_bucket.objects.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "objects" {
  bucket = aws_s3_bucket.objects.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_policy" "objects" {
  bucket = aws_s3_bucket.objects.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.objects.arn, "${aws_s3_bucket.objects.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.objects]
}

# Sandbox용 1시간 credential. Agent Delivery가 AssumeRole하면서 session policy로 리소스 prefix 하나로 좁힙니다.
resource "aws_iam_role" "sandbox_objects" {
  name                 = "agent-delivery-sandbox-objects"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.delivery_role_arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sandbox_objects" {
  name = "objects"
  role = aws_iam_role.sandbox_objects.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListTenantPrefixes"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.objects.arn
      },
      {
        Sid      = "TenantObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"]
        Resource = "${aws_s3_bucket.objects.arn}/*"
      },
    ]
  })
}

# 배포된 테넌트 앱(namespace `app-<project>-<env>`, SA `app`)의 Pod Identity 역할입니다.
# Agent Delivery가 bucket 리소스가 있는 namespace에만 association을 만듭니다.
# Pod Identity session tag로 자기 namespace prefix만 허용하므로 역할 하나를 모든 테넌트가 공유합니다.
resource "aws_iam_role" "tenant_objects" {
  name = "agent-delivery-tenant-objects"
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

resource "aws_iam_role_policy" "tenant_objects" {
  name = "objects"
  role = aws_iam_role.tenant_objects.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListOwnNamespace"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.objects.arn
        Condition = {
          StringLike = { "s3:prefix" = ["$${aws:PrincipalTag/eks-cluster-name}/$${aws:PrincipalTag/kubernetes-namespace}/*"] }
        }
      },
      {
        Sid      = "OwnNamespaceObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"]
        Resource = "${aws_s3_bucket.objects.arn}/$${aws:PrincipalTag/eks-cluster-name}/$${aws:PrincipalTag/kubernetes-namespace}/*"
      },
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
    ]
  })
}
