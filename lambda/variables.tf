variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "server_callback_url" {
  description = "HTTP endpoint to forward events to via POST"
  type        = string
}

variable "dlq_arn" {
  description = "ARN of the SQS dead-letter queue"
  type        = string
}

variable "dlq_url" {
  description = "URL of the SQS dead-letter queue"
  type        = string
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
  }
}
