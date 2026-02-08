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

variable "repo_name" {
  description = "ECR repo name."
  type = string
}

variable "alb_name" {
  description = "Name for your load balancer."
  type        = string
}

variable "my_ip" {
  description = "IP address of your PC."
  type        = string
}