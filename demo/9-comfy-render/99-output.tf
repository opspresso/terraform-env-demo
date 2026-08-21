# output

output "table" {
  description = "DYNAMODB_TABLE_NAME"
  value       = aws_dynamodb_table.this.name
}

output "static_bucket" {
  description = "S3_BUCKET"
  value       = aws_s3_bucket.static.bucket
}
