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

variable "gcp_client_id" {}
variable "gcp_client_secret" { sensitive = true }