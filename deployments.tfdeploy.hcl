identity_token "aws" {
  audience = ["aws.workload.identity"]
}

store "varset" pp_secrets {
  name     = "pp_secrets"
  category = "terraform"
}

deployment "test" {
  inputs = {
    regions            = ["ca-central-1"]
    role_arn           = "arn:aws:iam::659271373941:role/TerraformAdminAccessOIDC"
    identity_token     = identity_token.aws.jwt
    gcp_client_id      = store.varset.pp_secrets.stable.gcp_client_id
    gcp_client_secret  = store.varset.pp_secrets.stable.gcp_client_secret
    server_domain_name = "pledgeproof-server.zynclo.com"
    my_ip              = "94.156.148.51" # curl ifconfig.me
    default_tags = {
      App         = "PledgeProof"
      Environment = "Test"
    }
  }
}
