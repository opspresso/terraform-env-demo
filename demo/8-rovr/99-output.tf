output "sandbox_cache_file_system_id" {
  description = "argocd-env-apps env/eks-demo.yaml의 rovr.sandbox.cache.file_system_id 값입니다."
  value       = aws_efs_file_system.sandbox_cache.id
}

output "sandbox_cache_access_point_id" {
  description = "argocd-env-apps env/eks-demo.yaml의 rovr.sandbox.cache.access_point_id 값입니다."
  value       = aws_efs_access_point.sandbox_cache.id
}
