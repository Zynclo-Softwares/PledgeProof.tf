variable "domain_name" {
  description = "Domain for cert, e.g., pledgeproof.zynclo.com"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to resources"
  type        = map(string)
  default     = {}
}

data "aws_route53_zone" "zynclo" {
  name         = "zynclo.com"
  private_zone = false
}