variable "table_name" {
  description = "dynamodb table name."
  type = string
}

variable "default_tags" {
  description = "default tags to apply to all resources."
  type    = map(string)
  default = {}
}

variable "billing_mode" {
  description = "DynamoDB billing mode: PAY_PER_REQUEST or PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "Provisioned RCUs (only when billing_mode is PROVISIONED)."
  type        = number
  default     = 0
}

variable "write_capacity" {
  description = "Provisioned WCUs (only when billing_mode is PROVISIONED)."
  type        = number
  default     = 0
}

variable "enable_dev_table" {
  description = "Create an additional dev table alongside the main table."
  type        = bool
  default     = false
}