variable "default_tags" {
  description = "default tags to apply to all resources."
  type    = map(string)
  default = {}
}

variable "event_bus_name" {
  description = "name of the unified event bus."
  type = string
}

variable "dlq_name" {
  description = "name of the dead letter queue attached to event bus."
  type = string
}

data "aws_region" "current" {}