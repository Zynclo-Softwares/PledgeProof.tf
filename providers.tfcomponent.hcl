required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 6.0" # ✅ Supports bus DLQ + latest [web:373]
  }
}
provider "aws" "configurations" {
  for_each = var.regions
  config {
    region = each.value
    assume_role_with_web_identity {
      role_arn           = var.role_arn
      web_identity_token = var.identity_token
    }
    default_tags { tags = var.default_tags }
  }
}

# Fixed us-east-1 provider for Cognito custom domain ACM cert (CloudFront requirement)
provider "aws" "us_east_1" {
  config {
    region = "us-east-1"
    assume_role_with_web_identity {
      role_arn           = var.role_arn
      web_identity_token = var.identity_token
    }
    default_tags { tags = var.default_tags }
  }
}

