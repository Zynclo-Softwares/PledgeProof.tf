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
    table_name       = "pledgeproof-${local.deployment}"
    billing_mode     = var.dynamodb_billing_mode
    read_capacity    = var.dynamodb_read_capacity
    write_capacity   = var.dynamodb_write_capacity
    enable_dev_table = var.enable_dev_table
    default_tags     = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "cognito" {
  for_each = var.regions
  source   = "./cognito"
  inputs = {
    pool_name             = "pledgeproof-${local.deployment}"
    cognito_custom_domain = var.cognito_custom_domain
    app_scheme            = "pledgeproofai"
    default_tags          = var.default_tags
    gcp_client_id         = var.gcp_client_id
    gcp_client_secret     = var.gcp_client_secret
  }
  providers = {
    aws           = provider.aws.configurations[each.value]
    aws.us_east_1 = provider.aws.us_east_1
  }
}

component "dinov2" {
  for_each = var.regions
  source   = "./dinov2-ml"
  inputs = {
    function_name = "pledgeproof-dinov2-${local.deployment}"
    ecr_repo_name = "pledgeproof-dinov2"
    image_tag     = var.dinov2_image_tag
    memory_size   = var.dinov2_memory_size
    timeout       = var.dinov2_timeout
    default_tags  = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "alb" {
  for_each = var.regions
  source   = "./alb"
  inputs = {
    alb_domain_name = var.server_domain_name
    alb_name        = "pledgeproof-alb-${local.deployment}"
    default_tags    = var.default_tags
  }
  providers = { aws = provider.aws.configurations[each.value] }
}

component "compute" {
  for_each = var.regions
  source   = "./compute"
  inputs = {
    default_tags         = var.default_tags
    ecr_repo_name        = "pledgeproof-server"
    task_name            = "pledgeproof-task-${local.deployment}"
    container_name       = "pledgeproof-container"
    ecs_cluster_name     = "pledgeproof-cluster-${local.deployment}"
    target_group_arn     = component.alb[each.key].alb_target_group_arn
    alb_sg_id            = component.alb[each.key].alb_security_group_id
    container_port       = 80
    task_cpu             = var.compute_cpu
    task_memory          = var.compute_memory
    max_count            = var.compute_max_count
    health_check_command = ["/bin/httpcheck", "http://localhost:80/health"]
    ecr_img_uri          = "${component.compute[each.key].ecr_repo_uri}:latest"
    dynamodb_table_arn   = component.dynamodb[each.key].table_arn
    s3_bucket_arn        = component.s3[each.key].bucket_arn
    dinov2_lambda_arn    = component.dinov2[each.key].function_arn
    task_env = {
      QSTASH_TOKEN                = var.qstash_token
      QSTASH_CURRENT_SIGNING_KEY  = var.qstash_current_signing_key
      QSTASH_NEXT_SIGNING_KEY     = var.qstash_next_signing_key
      ADMIN_PASS                  = var.admin_pass
      GITHUB_APP_ID               = var.github_app_id
      GITHUB_INSTALLATION_ID      = var.github_installation_id
      GITHUB_PRIVATE_KEY_PATH     = var.github_private_key
      GITHUB_WEBHOOK_SECRET       = var.github_webhook_secret
      REVENUECAT_API_KEY          = var.revenuecat_api_key
      DYNAMO_TABLE                = component.dynamodb[each.key].table_name
      S3_BUCKET                   = component.s3[each.key].bucket_id
      DINOV2_FUNCTION_NAME        = component.dinov2[each.key].function_name
      COGNITO_USER_POOL_ID        = component.cognito[each.key].user_pool_id
      SERVER_URL                  = "https://${var.server_domain_name}"
    }
  }
  providers = { aws = provider.aws.configurations[each.value] }
}
