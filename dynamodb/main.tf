resource "aws_dynamodb_table" "table" {
  name         = var.table_name
  
  hash_key     = "PK"    
  range_key    = "SK"    
  
  # Define ONLY your keys here—no JSON fields!
  attribute {
    name = "PK"
    type = "S"  
  }
  
  attribute {
    name = "SK" 
    type = "S"  
  }

	billing_mode = "PAY_PER_REQUEST"

	tags = var.default_tags
}
