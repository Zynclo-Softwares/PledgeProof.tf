resource "aws_ecs_cluster" "cluster" {
  name = var.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"  # CloudWatch metrics/logs (recommended)
  }
  tags = var.default_tags
}

resource "aws_ecs_cluster_capacity_providers" "fargate_providers" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]  # Optional Spot savings
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

resource "aws_ecs_service" "monolith_service" {
  name            = "pledgeproof-app"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
  tags = var.default_tags
}