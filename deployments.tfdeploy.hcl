identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "test" {
  inputs = {
    regions        = ["ca-central-1"]
    role_arn       = "arn:aws:iam::659271373941:role/TerraformAdminAccessOIDC"
    identity_token = identity_token.aws.jwt
    default_tags = {
      App         = "PledgeProof"
      Environment = "Test"
    }
  }
}
