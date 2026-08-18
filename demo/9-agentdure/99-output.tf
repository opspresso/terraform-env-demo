# output

output "tables" {
  description = "DYNAMODB_TABLE_NAME"
  value       = { for env, table in aws_dynamodb_table.this : env => table.name }
}

output "static_buckets" {
  description = "S3_BUCKET_NAME"
  value       = { for env, bucket in aws_s3_bucket.static : env => bucket.bucket }
}

output "vector_buckets" {
  description = "VECTOR_BUCKET"
  value       = { for env, bucket in aws_s3vectors_vector_bucket.this : env => bucket.vector_bucket_name }
}

output "memory_buckets" {
  description = "STATE_BUCKET — mcp-memory 의 상태"
  value       = { for env, bucket in aws_s3_bucket.memory : env => bucket.bucket }
}

output "document_buckets" {
  description = "Knowledge Base 가 읽어들일 문서를 올리는 곳"
  value       = { for env, bucket in aws_s3_bucket.documents : env => bucket.bucket }
}

output "knowledge_base_ids" {
  value = { for env, kb in aws_bedrockagent_knowledge_base.this : env => kb.id }
}

output "idc_user" {
  description = "IDC 호스트가 쓰는 IAM 사용자. 액세스 키는 terraform 이 만들지 않습니다."
  value       = aws_iam_user.idc.name
}
