identity_token "aws" {
  audience = ["aws.workload.identity"]
}

store "varset" pp_secrets {
  name     = "pp_secrets"
  category = "terraform"
}

deployment "prod" {
  inputs = {
    regions                    = ["ca-central-1"]
    role_arn                   = "arn:aws:iam::659271373941:role/TerraformAdminAccessOIDC"
    identity_token             = identity_token.aws.jwt
    gcp_client_id              = store.varset.pp_secrets.stable.gcp_client_id
    gcp_client_secret          = store.varset.pp_secrets.stable.gcp_client_secret
    cognito_custom_domain      = "auth.pledgeproof.com"
    server_domain_name         = "api.pledgeproof.com"
    qstash_token               = store.varset.pp_secrets.stable.qstash_token
    qstash_current_signing_key = store.varset.pp_secrets.stable.qstash_current_signing_key
    qstash_next_signing_key    = store.varset.pp_secrets.stable.qstash_next_signing_key
    admin_pass                 = store.varset.pp_secrets.stable.admin_pass
    github_app_id              = store.varset.pp_secrets.stable.github_app_id
    github_installation_id     = store.varset.pp_secrets.stable.github_installation_id
    github_private_key         = store.varset.pp_secrets.stable.github_private_key
    github_webhook_secret      = store.varset.pp_secrets.stable.github_webhook_secret
    revenuecat_api_key         = store.varset.pp_secrets.stable.revenuecat_api_key
    enable_dev_table           = true

    // DINOv2 Lambda tuning (defaults: 1536 MB, 30s, "latest")
    dinov2_memory_size = 1536
    dinov2_timeout     = 30
    dinov2_image_tag   = "latest"

    // Compute / ECS tuning (defaults: 256 CPU, 512 MB, max 1 task)
    compute_cpu       = 256
    compute_memory    = 512
    compute_max_count = 1

    // DynamoDB tuning (default: on-demand)
    dynamodb_billing_mode   = "PAY_PER_REQUEST"
    dynamodb_read_capacity  = 0
    dynamodb_write_capacity = 0

    default_tags = {
      App         = "PledgeProof"
      Environment = "prod"
    }
  }
}
