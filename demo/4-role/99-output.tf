# output

output "role_names" {
  value = [for role in aws_iam_role.this : role.name]
}

# Pod Identity association 은 이제 5-eks 가 겁니다 — 클러스터가 있어야 걸 수 있는 것이라
# 클러스터를 만드는 쪽의 일입니다. 그쪽이 ARN 을 문자열로 조립하지 않도록 여기서 내보냅니다.
output "role_arns" {
  description = "역할 키 → ARN. 5-eks 가 remote state 로 읽습니다."
  value       = { for key, role in aws_iam_role.this : key => role.arn }
}
