# The account's GitHub Actions OIDC provider. Repository roles that trust it live in terraform-env-opsp.

# An account has at most one provider per URL. Reuse the existing one unless this root should create it.
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 0 : 1

  arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

locals {
  github_oidc_provider_arn = one(concat(aws_iam_openid_connect_provider.github[*].arn, data.aws_iam_openid_connect_provider.github[*].arn))
}
