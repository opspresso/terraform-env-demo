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

output "cluster_certificate_authority_data" {
  description = "6-eks-node의 Kubernetes provider가 사용하는 Base64 인코딩 CA 인증서입니다."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_region" {
  value = var.region
}

output "cluster_iam_role_name" {
  value = module.eks.cluster_iam_role_name
}

output "cluster_status" {
  value = module.eks.cluster_status
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "workspace_node_role_name" {
  description = "Existing Auto Mode node role reused by the workspace NodeClass."
  value       = module.eks.node_iam_role_name
}

output "workspace_subnet_ids" {
  value = local.private_subnets
}

output "workspace_security_group_id" {
  description = "EKS-managed primary security group used by Auto Mode nodes."
  value       = module.eks.cluster_primary_security_group_id
}

output "oidc_provider" {
  value = module.eks.oidc_provider
}
