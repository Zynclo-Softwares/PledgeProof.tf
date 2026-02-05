variable "default_tags" {
  description = "default tags to apply to all resources."
  type    = map(string)
  default = {}
}

variable "dlq_name" {
  description = "name of the dead letter queue attached to lambda."
  type = string
}