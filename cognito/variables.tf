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

variable "apple_services_id" {
  description = "Apple Services ID for Sign In with Apple."
  type        = string
}

variable "apple_team_id" {
  description = "Apple Team ID."
  type        = string
}

variable "apple_key_id" {
  description = "Apple Key ID for Sign In with Apple."
  type        = string
}

variable "apple_private_key" {
  description = "Apple private key (.p8) contents for Sign In with Apple."
  type        = string
  sensitive   = true
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