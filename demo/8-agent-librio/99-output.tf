output "source_bucket" {
  description = "S3_BUCKET_NAME for a future EKS Librio installation."
  value       = aws_s3_bucket.sources.bucket
}

output "source_bucket_arn" {
  value = aws_s3_bucket.sources.arn
}
