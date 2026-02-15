output "bucket_id" {
  description = "The ID of the S3 bucket to be used by a downstream component in this stack."
  value       = aws_s3_bucket.static_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.static_bucket.arn
}