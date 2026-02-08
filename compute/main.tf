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
  name            = "${var.task_name}-service"
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

  network_configuration {
    subnets          = data.aws_subnets.default_vpc.ids
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = true
  }

  tags = var.default_tags
  lifecycle {
    ignore_changes = [desired_count,task_definition]  # Allow manual scaling without Terraform conflicts
  }
}