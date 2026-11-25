# Public routing and cluster identifiers that other stacks and installers read by name.
# Each secret is /k8s/common/<cluster>/<key> with a plain string value.
locals {
  published_metadata = {
    cluster_oidc_url = module.eks.cluster_oidc_issuer_url
    cluster_version  = module.eks.cluster_version
  }
}

resource "aws_secretsmanager_secret" "metadata" {
  for_each = local.published_metadata
  name     = "/k8s/common/${var.name}/${each.key}"
}

resource "aws_secretsmanager_secret_version" "metadata" {
  for_each      = local.published_metadata
  secret_id     = aws_secretsmanager_secret.metadata[each.key].id
  secret_string = each.value
}
