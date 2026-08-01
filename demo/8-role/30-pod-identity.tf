# Pod Identity Association

locals {
  # 애드온별 네임스페이스/서비스어카운트. 키는 role 키(policies/ 파일명 또는
  # additional_policies 키)와 일치해야 하며, 어긋나면 plan 단계에서 실패합니다.
  pod_identity_targets = {
    "agent-studio" = {
      namespace       = "agent-studio"
      service_account = "agent-studio"
    }
    "atlantis" = {
      namespace       = "addon-atlantis"
      service_account = "atlantis"
    }
    "external-dns" = {
      namespace       = "addon-external-dns"
      service_account = "external-dns"
    }
    "external-secrets" = {
      namespace       = "addon-external-secrets"
      service_account = "external-secrets"
    }
    "mcp-memory" = {
      namespace       = "agent-mcps"
      service_account = "mcp-memory"
    }
  }

  # role_name/role_arn 을 문자열로 짜맞추지 않고 실제 리소스에서 가져옵니다.
  pod_identity_associations = {
    for key, value in local.pod_identity_targets : key => {
      role_name       = aws_iam_role.this[key].name
      role_arn        = aws_iam_role.this[key].arn
      namespace       = value.namespace
      service_account = value.service_account
    }
  }
}

# output

output "pod_identity_associations" {
  description = "eks pod-identity-associations"
  value       = local.pod_identity_associations
}
