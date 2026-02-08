variable "default_tags" {
  description = "default tags to apply to all resources."
  type    = map(string)
  default = {}
}

variable "pool_name" {
  description = "cognito user pool name."
  type = string
}

variable "cognito_domain_name" {
  description = "cognito user pool google oauth redirection domain."
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

data "aws_region" "current" {}