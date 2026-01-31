variable "regions" { type = set(string) }
variable "role_arn" { type = string }
variable "aws_token" {
  type      = string
  ephemeral = true
}
variable "tags" {
  type    = map(string)
  default = {}
}