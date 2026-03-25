variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "ecr_repo_name" {
  description = "ECR repository name for the Resend sync container image"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 120
}

variable "resend_api_key" {
  description = "Resend API key for contact sync"
  type        = string
  sensitive   = true
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID to fetch emails from"
  type        = string
  default     = "ca-central-1_NFOMStQGX"
}

variable "schedule_timezone" {
  description = "IANA timezone for the schedule"
  type        = string
  default     = "America/Toronto"
}

variable "default_tags" {
  type    = map(string)
  default = {}
}
