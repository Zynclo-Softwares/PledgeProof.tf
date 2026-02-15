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

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "alb_sg_id" {
  description = "Security group ID of the ALB to allow traffic from."
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group to attach the service to."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table the task can access."
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket the task can access."
  type        = string
}

variable "task_env" {
  description = "Environment variables to pass to the container."
  type        = map(string)
  default     = {}
}

data "aws_region" "current" {}

data "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_vpc" "default" {
  default = true
}

# get all default subnets in the default vpc
data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}
