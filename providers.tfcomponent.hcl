required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 6.0"
  }
  railway = {
    source  = "terraform-community-providers/railway"
    version = "~> 0.5"
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

# Railway provider — singleton (Railway is external to AWS regions). The token
# must be a Railway ACCOUNT or WORKSPACE token (from railway.com → account/
# workspace settings → Tokens), NOT a project token — the provider creates the
# project. Supplied via var.railway_token (HCP varset).
provider "railway" "this" {
  config {
    token = var.railway_token
  }
}

