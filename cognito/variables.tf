variable "default_tags" {
  description = "default tags to apply to all resources."
  type    = map(string)
  default = {}
}

variable "pool_name" {
  description = "cognito user pool name."
  type = string
}

variable "cognito_custom_domain" {
  description = "Custom domain for Cognito OAuth (e.g., auth.pledgeproof.zynclo.com)"
  type = string
}

variable "gcp_client_id" {
    description = "GCP OAuth Client ID."
    type = string
}

variable "gcp_client_secret" { 
    description = "GCP OAuth Client Secret."
    type = string
    sensitive = true
}

variable "app_scheme" {
  description = "Where google oauth would return back to as a callback."
  type        = string
}

variable "post_confirmation_lambda_arn" {
  description = "Lambda ARN invoked after user confirmation (manual verify or Google sign-in)"
  type        = string
}

data "aws_region" "current" {}

data "aws_route53_zone" "zynclo" {
  name         = "zynclo.com"
  private_zone = false
}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}