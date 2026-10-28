output "source_bucket" {
  description = "S3_BUCKET_NAME of Agent Knowledge."
  value       = aws_s3_bucket.sources.bucket
}

output "source_bucket_arn" {
  value = aws_s3_bucket.sources.arn
}
