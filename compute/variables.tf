variable "default_tags" {
  description = "Default tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "ecr_repo_name" {
  description = "Your ecr repository name."
  type = string
}


variable "task_name" {
    description = "Name of the ECS task."
    type = string
}

variable "container_name" {
  description = "Name of the container in the task definition."
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens."
  type        = number
}

variable "health_check_command" {
  description = "An array of cli commands."
  type = list(string)
}

variable "ecr_img_uri" {
  description = "the image to deploy"
  type = string
}

data "aws_region" "current" {}

