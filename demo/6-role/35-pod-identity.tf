# Pod Identity Association

locals {
  pod_identity_associations = {
    "atlantis" = {
      role_name       = "pod-role--atlantis"
      namespace       = "addon-atlantis"
      service_account = "atlantis"
    }
    "external-dns" = {
      role_name       = "pod-role--external-dns"
      namespace       = "addon-external-dns"
      service_account = "external-dns"
    }
    "external-secrets" = {
      role_name       = "pod-role--external-secrets"
      namespace       = "addon-external-secrets"
      service_account = "external-secrets"
    }
  }
}

# output

output "pod_identity_associations" {
  description = "eks pod-identity-associations"
  value       = local.pod_identity_associations
}
