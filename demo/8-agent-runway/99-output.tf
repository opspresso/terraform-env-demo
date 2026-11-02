output "kms_key_arn" {
  value = aws_kms_key.variables.arn
}

output "tenant_objects_role_arn" {
  value = aws_iam_role.runway_tenant_objects.arn
}

output "tenant_secrets_role_arn" {
  value = aws_iam_role.runway_tenant_secrets.arn
}
