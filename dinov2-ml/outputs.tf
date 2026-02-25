output "function_arn" {
  description = "ARN of the DINOv2 Lambda function"
  value       = aws_lambda_function.dinov2.arn
}

output "function_name" {
  description = "Name of the DINOv2 Lambda function"
  value       = aws_lambda_function.dinov2.function_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the DINOv2 image"
  value       = aws_ecr_repository.dinov2.repository_url
}
