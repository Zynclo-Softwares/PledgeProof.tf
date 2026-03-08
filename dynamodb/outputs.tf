output "table_name" {
  value = aws_dynamodb_table.table.name  
}

output "table_arn" {
  value = aws_dynamodb_table.table.arn
}

output "dev_table_name" {
  value = var.enable_dev_table ? aws_dynamodb_table.dev_table[0].name : null
}

output "dev_table_arn" {
  value = var.enable_dev_table ? aws_dynamodb_table.dev_table[0].arn : null
}