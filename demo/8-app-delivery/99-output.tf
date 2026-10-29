output "push_role_arn" {
  value = aws_iam_role.push.arn
}

output "registry" {
  description = "앱 이미지 repository의 접두어. repository 이름은 `projects/<slug>`입니다."
  value       = "${local.account_id}.dkr.ecr.${var.region}.amazonaws.com/projects"
}

output "rds_subnet_group_name" {
  description = "RdsPostgres의 DB subnet group. argocd-env-addons env의 `delivery_resources.rds.subnet_group`입니다."
  value       = aws_db_subnet_group.rds.name
}

output "rds_security_group_id" {
  description = "RdsPostgres의 security group. argocd-env-addons env의 `delivery_resources.rds.security_group_id`입니다."
  value       = aws_security_group.rds.id
}

output "rds_parameter_group_name" {
  description = "RdsPostgres의 DB parameter group(TLS 강제). argocd-env-addons env의 `delivery_resources.rds.parameter_group`입니다."
  value       = aws_db_parameter_group.rds.name
}

output "valkey_security_group_id" {
  description = "ValkeyCache의 security group. argocd-env-addons env의 `delivery_resources.valkey.security_group_id`입니다."
  value       = aws_security_group.valkey.id
}

output "intra_subnet_ids" {
  description = "RDS·Valkey가 쓰는 intra subnet. argocd-env-addons env의 `delivery_resources.valkey.subnet_ids`입니다."
  value       = data.terraform_remote_state.vpc.outputs.intra_subnets
}
