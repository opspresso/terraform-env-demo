# output

output "role_names" {
  value = [for role in aws_iam_role.this : role.name]
}
