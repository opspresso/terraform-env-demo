output "kms_key_arn" {
  value = aws_kms_key.variables.arn
}

output "objects_bucket" {
  value = aws_s3_bucket.runway_objects.id
}

output "sandbox_objects_role_arn" {
  value = aws_iam_role.runway_sandbox_objects.arn
}

output "tenant_objects_role_arn" {
  value = aws_iam_role.runway_tenant_objects.arn
}

output "tenant_secrets_role_arn" {
  value = aws_iam_role.runway_tenant_secrets.arn
}
