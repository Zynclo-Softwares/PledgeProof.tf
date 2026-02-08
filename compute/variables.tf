variable "default_tags" {
  description = "Default tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "ecr_repo_name" {
  description = "your ecr repository name."
  type = string
}