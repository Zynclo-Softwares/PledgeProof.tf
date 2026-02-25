component "s3" {
  for_each = var.regions
  source   = "./s3"
  inputs = {
    # S3 names are globally unique — include both region and environment
    bucket_name  = "pledgeproof-${local.deployment}-${each.value}"
    default_tags = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "dynamodb" {
  for_each = var.regions
  source   = "./dynamodb"
  inputs = {
    table_name   = "pledgeproof-${local.deployment}"
    default_tags = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "cognito" {
  for_each = var.regions
  source   = "./cognito"
  inputs = {
    pool_name                    = "pledgeproof-${local.deployment}"
    cognito_custom_domain        = var.cognito_custom_domain
    app_scheme                   = "pledgeproofai"
    default_tags                 = var.default_tags
    gcp_client_id                = var.gcp_client_id
    gcp_client_secret            = var.gcp_client_secret
    post_confirmation_lambda_arn = component.lambda[each.key].function_arn
  }
  providers = {
    aws           = provider.aws.configurations[each.value]
    aws.us_east_1 = provider.aws.us_east_1
  }
}

component "sqs" {
  for_each = var.regions
  source   = "./sqs"
  inputs = {
    dlq_name     = "pledge-lambda-dlq-${local.deployment}"
    default_tags = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "lambda" {
  for_each = var.regions
  source   = "./lambda"
  inputs = {
    function_name       = "pledgeproof-event-proxy-${local.deployment}"
    server_callback_url = "https://${var.server_domain_name}/webhooks/events"
    dlq_arn             = component.sqs[each.key].lambda_dlq_arn
    dlq_url             = component.sqs[each.key].lambda_dlq_url
    default_tags        = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "dinov2" {
  for_each = var.regions
  source   = "./dinov2-ml"
  inputs = {
    function_name = "pledgeproof-dinov2-${local.deployment}"
    ecr_repo_name = "pledgeproof-dinov2"
    image_tag     = "latest"
    memory_size   = 1536
    timeout       = 30
    default_tags  = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

# component "alb" {
#   for_each = var.regions
#   source   = "./alb"
#   inputs = {
#     alb_domain_name = var.server_domain_name
#     alb_name        = "pledgeproof-alb-${local.deployment}"
#     default_tags    = var.default_tags
#   }
#   providers = { aws = provider.aws.configurations[each.value] }
# }

# component "compute" {
#   for_each = var.regions
#   source   = "./compute"
#   inputs = {
#     default_tags         = var.default_tags
#     ecr_repo_name        = "zynclo-softwares"
#     task_name            = "pledgeproof-task-${local.deployment}"
#     container_name       = "pledgeproof-container"
#     ecs_cluster_name     = "zynclo-ecs-cluster-${local.deployment}"
#     target_group_arn     = "${component.alb[each.key].alb_target_group_arn}"
#     alb_sg_id            = "${component.alb[each.key].alb_security_group_id}"
#     container_port       = 80
#     health_check_command = ["/bin/httpcheck", "http://localhost:80/health"]
#     ecr_img_uri          = "659271373941.dkr.ecr.ca-central-1.amazonaws.com/zynclo-softwares@sha256:3c780a2fa799564eed5ec08800cef52d632305157d050790e92c74c5403603aa"
#     dynamodb_table_arn   = component.dynamodb[each.key].table_arn
#     s3_bucket_arn        = component.s3[each.key].bucket_arn
#     task_env = {
#       UPSTASH_API_KEY = var.upstash_api_key
#     }
#   }
#   providers = { aws = provider.aws.configurations[each.value] }
# }
