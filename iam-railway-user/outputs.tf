output "user_name" {
  description = "IAM user name."
  value       = aws_iam_user.this.name
}

output "user_arn" {
  description = "IAM user ARN."
  value       = aws_iam_user.this.arn
}

output "access_key_id" {
  description = "Access key id — inject as AWS_ACCESS_KEY_ID on the Railway service."
  value       = aws_iam_access_key.this.id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret access key — inject as AWS_SECRET_ACCESS_KEY on the Railway service."
  value       = aws_iam_access_key.this.secret
  sensitive   = true
}
