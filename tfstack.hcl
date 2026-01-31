# MERGE ALL - HCP will recognize THIS file
required_providers {
  aws = { source = "hashicorp/aws", version = "~> 5.7.0" }
}

variable "regions" { type = set(string) }
variable "role_arn" { type = string }
variable "aws_token" { type = string; ephemeral = true }
variable "tags" { type = map(string); default = {} }

provider "aws" "configurations" {
  for_each = var.regions
  config {
    region = each.value
    assume_role_with_web_identity {
      role_arn = var.role_arn
      web_identity_token = var.aws_token
    }
    default_tags { tags = var.tags }
  }
}

component "s3" {
  for_each = var.regions
  source = "./s3"
  inputs = {
    region = each.value
    bucket_name = "test-bucket-${each.value}"
  }
  providers = { aws = provider.aws.configurations[each.value] }
}
