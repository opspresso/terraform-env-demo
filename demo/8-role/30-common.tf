# Pod Identity Association

locals {
  common_targets = {
    "external-dns" = {
      namespace       = "addon-external-dns"
      service_account = "external-dns"
    }
    "external-secrets" = {
      namespace       = "addon-external-secrets"
      service_account = "external-secrets"
    }
  }

  # role_name/role_arn 을 문자열로 짜맞추지 않고 실제 리소스에서 가져옵니다.
  common_items = {
    for key, value in local.common_targets : key => {
      role_name       = aws_iam_role.this[key].name
      role_arn        = aws_iam_role.this[key].arn
      namespace       = value.namespace
      service_account = value.service_account
    }
  }
}
