output "push_role_arn" {
  value = aws_iam_role.push.arn
}

output "registry" {
  description = "앱 이미지 repository의 접두어. repository 이름은 `projects/<slug>`입니다."
  value       = "${local.account_id}.dkr.ecr.${var.region}.amazonaws.com/projects"
}
