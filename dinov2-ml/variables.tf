variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "ecr_repo_name" {
  description = "ECR repository name for the DINOv2 container image"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "memory_size" {
  description = "Lambda memory in MB (CPU scales proportionally)"
  type        = number
  default     = 1536
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "default_tags" {
  type    = map(string)
  default = {}
}
