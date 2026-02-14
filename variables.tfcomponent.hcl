variable "regions" { type = set(string) }
variable "role_arn" { type = string }
variable "identity_token" {
  type      = string
  ephemeral = true
}
variable "default_tags" {
  type    = map(string)
  default = {}
}

variable "gcp_client_id" {
  description = "GCP OAuth Client ID."
  type        = string
}
variable "gcp_client_secret" {
  description = "GCP OAuth Client Secret."
  type        = string
  sensitive   = true
}

variable "server_domain_name" {
  description = "Domain for cert & server"
  type        = string
}

variable "cognito_custom_domain" {
  description = "Custom domain for Cognito OAuth (e.g., auth.pledgeproof.zynclo.com)"
  type        = string
}

variable "my_ip" {
  description = "IP address of your PC."
  type        = string
}

locals {
  deployment = var.default_tags["Environment"]
}