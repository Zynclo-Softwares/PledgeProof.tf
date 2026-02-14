output "function_arn" {
  value = aws_lambda_function.event_proxy.arn
}

output "function_name" {
  value = aws_lambda_function.event_proxy.function_name
}
