resource "aws_dynamodb_table" "table" {
  name = var.table_name

  deletion_protection_enabled = true

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

  attribute {
    name = "startTimeUtc"
    type = "S"
  }

  global_secondary_index {
    name            = "startTimeUtc-index"
    hash_key        = "startTimeUtc"
    range_key       = "SK"
    projection_type = "ALL"
  }

  # Inverse index: query all items for a given SK (e.g. SK = "PROFILE" to list
  # every user id). Used by repository/profile.listAllUserIds — consumed by the
  # dst-fix cron and the admin broadcast. KEYS_ONLY is enough (only PK is read).
  global_secondary_index {
    name            = "SK-PK-index"
    hash_key        = "SK"
    range_key       = "PK"
    projection_type = "KEYS_ONLY"
  }

  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  point_in_time_recovery {
    enabled = true
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = var.default_tags
}

resource "aws_dynamodb_table" "dev_table" {
  count = var.enable_dev_table ? 1 : 0

  name = "${var.table_name}-dev"

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

  attribute {
    name = "startTimeUtc"
    type = "S"
  }

  global_secondary_index {
    name            = "startTimeUtc-index"
    hash_key        = "startTimeUtc"
    range_key       = "SK"
    projection_type = "ALL"
  }

  # Inverse index (SK → PK), mirrors the prod table. Used by listAllUserIds.
  global_secondary_index {
    name            = "SK-PK-index"
    hash_key        = "SK"
    range_key       = "PK"
    projection_type = "KEYS_ONLY"
  }

  billing_mode = "PAY_PER_REQUEST"

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags         = merge(var.default_tags, { Environment = "dev" })
}
