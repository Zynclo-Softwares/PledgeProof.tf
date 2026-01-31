identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "test" {
  inputs = {
    regions   = toset(["ca-central-1"])
    role_arn  = "arn:aws:iam::659271373941:role/TerraformAdminAccessOIDC"
    aws_token = identity_token.aws.jwt
    tags      = { stack_test = "pp-s3" }
  }
}
