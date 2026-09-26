# output

output "table" {
  description = "DYNAMODB_TABLE_NAME"
  value       = aws_dynamodb_table.this.name
}

output "static_bucket" {
  description = "S3_BUCKET"
  value       = aws_s3_bucket.static.bucket
}

output "render_queue" {
  description = "SQS_QUEUE_NAME"
  value       = aws_sqs_queue.render.name
}

output "render_dead_letter_queue" {
  description = "SQS_DLQ_NAME"
  value       = aws_sqs_queue.render_dead_letter.name
}

output "app_access_policy_arn" {
  value = aws_iam_policy.app_access.arn
}

output "amplify_compute_role_arn" {
  value = aws_iam_role.amplify_compute.arn
}
