output "function_arn" {
  description = "ARN of the PDF-to-Image Lambda function"
  value       = aws_lambda_function.pdf2img.arn
}

output "function_name" {
  description = "Name of the PDF-to-Image Lambda function"
  value       = aws_lambda_function.pdf2img.function_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the PDF-to-Image image"
  value       = aws_ecr_repository.pdf2img.repository_url
}
