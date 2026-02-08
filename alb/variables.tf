variable "default_tags" {
  description = "Default tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "alb_name" {
  description = "Name for your load balancer."
  type = string
}

variable "my_ip" {
  description = "ip of your pc."
  type = string
}

variable "alb_domain_name" {
  description = "Domain for cert, e.g., pledgeproof.zynclo.com"
  type        = string
}

data "aws_route53_zone" "zynclo" {
  name         = "zynclo.com"
  private_zone = false
}

# get default subnet ids for the default vpc that are public
data "aws_vpc" "default" {
  default = true
}

# get all default subnets in the default vpc
data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}