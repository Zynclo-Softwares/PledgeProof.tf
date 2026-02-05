output "lambda_dlq_id" {
  value = aws_sqs_queue.lambda_dlq.id
}

output "lambda_dlq_arn" {
  value = aws_sqs_queue.lambda_dlq.arn
}

