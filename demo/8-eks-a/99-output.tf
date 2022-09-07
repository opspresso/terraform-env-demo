# output

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_version" {
  value = module.eks.cluster_version
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_role_name" {
  value = module.eks.cluster_role_name
}

output "cluster_oidc_arn" {
  value = module.eks.cluster_oidc_arn
}

output "cluster_oidc_url" {
  value = module.eks.cluster_oidc_url
}

output "cluster_vpc_config" {
  value = module.eks.cluster_vpc_config.0
}

output "worker_role_name" {
  value = local.worker_role_name
}

output "worker_security_group" {
  value = local.worker_security_groups
}
