# output

output "static_buckets" {
  description = "S3_BUCKET_NAME"
  value       = { for env, bucket in aws_s3_bucket.static : env => bucket.bucket }
}

output "ecr_repositories" {
  value = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "github_ecr_role_arns" {
  description = "Repository-specific GitHub Actions release roles."
  value       = { for repository, role in aws_iam_role.github_ecr : repository => role.arn }
}
