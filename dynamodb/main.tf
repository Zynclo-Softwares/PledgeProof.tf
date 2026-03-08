resource "aws_dynamodb_table" "table" {
  name         = var.table_name
  
  hash_key     = "PK"    
  range_key    = "SK"    

  deletion_protection_enabled = true
  
  # Define ONLY your keys here—no JSON fields!
  attribute {
    name = "PK"
    type = "S"  
  }
  
  attribute {
    name = "SK" 
    type = "S"  
  }

	billing_mode   = var.billing_mode
	read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
	write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

	tags = var.default_tags
}

resource "aws_dynamodb_table" "dev_table" {
  count = var.enable_dev_table ? 1 : 0

  name     = "${var.table_name}-dev"
  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }
  attribute {
    name = "SK"
    type = "S"
  }

  billing_mode = "PAY_PER_REQUEST"
  tags         = merge(var.default_tags, { Environment = "dev" })
}
