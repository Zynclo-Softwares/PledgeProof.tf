variable "bucket_name" {
  type = string
}

variable "default_tags" {
  type    = map(string)
  default = {}
}