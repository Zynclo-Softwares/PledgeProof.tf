variable "table_name" {
  description = "dynamodb table name."
  type = string
}

variable "default_tags" {
  description = "default tags to apply to all resources."
  type    = map(string)
  default = {}
}