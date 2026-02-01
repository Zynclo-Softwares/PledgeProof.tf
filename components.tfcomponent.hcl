component "s3" {
  for_each = var.regions
  source   = "./s3"
  inputs = {
    # Unique bucket name (S3 names are global)
    bucket_name  = "pledgeproof-${each.value}"
    default_tags = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "dynamodb" {
  for_each = var.regions
  source   = "./dynamodb"
  inputs = {
    table_name   = "PledgeProof-${each.value}"
    default_tags = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "cognito" {
  for_each = var.regions
  source   = "./cognito"
  inputs = {
    pool_name         = "PledgeProof-${each.value}"
    domain_name       = "pledgeproof-${each.value}"
    default_tags      = var.default_tags
    gcp_client_id     = var.gcp_client_id
    gcp_client_secret = var.gcp_client_secret
  }
  providers = { aws = provider.aws.configurations[each.value] }
}
