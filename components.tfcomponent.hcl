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
    app_scheme        = "pledgeproofai"
    default_tags      = var.default_tags
    gcp_client_id     = var.gcp_client_id
    gcp_client_secret = var.gcp_client_secret
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "sqs" {
  for_each = var.regions
  source   = "./sqs"
  inputs = {
    dlq_name     = "pledge-lambda-dlq-${each.value}"
    default_tags = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "alb" {
  for_each = var.regions
  source   = "./alb"
  inputs = {
    domain_name  = var.server_domain_name
    alb_name     = var.alb_name
    my_ip        = var.my_ip
    default_tags = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

# removed {
#   for_each = var.regions  # or ["ca-central-1"] if single
#   from    = component.event_bus_and_rules[each.key]
#   source  = "./event-bus"  # original source path
#   providers = {
#     aws = provider.aws.configurations[each.key]
#   }
# }
