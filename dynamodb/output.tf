output "table_name" {
  value = aws_dynamodb_table.pledge_proofs.name  
}

output "table_arn" {
  value = aws_dynamodb_table.pledge_proofs.arn
}