output "kms_key_arn" {
  value = aws_kms_key.variables.arn
}

output "objects_bucket" {
  value = aws_s3_bucket.objects.id
}

output "sandbox_objects_role_arn" {
  value = aws_iam_role.sandbox_objects.arn
}

output "tenant_objects_role_arn" {
  value = aws_iam_role.tenant_objects.arn
}

output "tenant_secrets_role_arn" {
  value = aws_iam_role.tenant_secrets.arn
}
