output "function_arn" {
  description = "ARN of the Resend Sync Lambda function"
  value       = aws_lambda_function.resend_sync.arn
}

output "function_name" {
  description = "Name of the Resend Sync Lambda function"
  value       = aws_lambda_function.resend_sync.function_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the Resend Sync image"
  value       = aws_ecr_repository.resend_sync.repository_url
}
