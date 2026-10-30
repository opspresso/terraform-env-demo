# GitHub Actions identities. They are separate from the Pod Identity roles above.

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# argocd-env-addons CI pulls the ACK charts from oci://public.ecr.aws. Anonymous pulls share a per-IP data limit
# with every other GitHub-hosted runner and fail with 429; an authenticated pull does not have that limit.
# The role can only get the ECR Public pull token. Main and the scoped Runway cutover validation branch can assume it.
resource "aws_iam_role" "github_ecr_public_pull" {
  name                 = "github--argocd-env-addons-ecr-public"
  description          = "argocd-env-addons CI pulls public.ecr.aws charts with an authenticated token"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          # The repository uses the default subject format (immutable subjects are off).
          "token.actions.githubusercontent.com:sub" = [
            "repo:opspresso/argocd-env-addons:ref:refs/heads/main",
            "repo:opspresso/argocd-env-addons:ref:refs/heads/feat/runway-tenant-cutover-20261030",
          ]
        }
      }
    }]
  })

  tags = {
    Name = "github--argocd-env-addons-ecr-public"
  }
}

resource "aws_iam_role_policy" "github_ecr_public_pull" {
  name = "ecr-public-pull-token"
  role = aws_iam_role.github_ecr_public_pull.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecr-public:GetAuthorizationToken", "sts:GetServiceBearerToken"]
      Resource = "*"
    }]
  })
}
