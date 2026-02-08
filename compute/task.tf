resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.task_name
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"  # 20-40% cheaper!
  }
  execution_role_arn = data.aws_iam_role.ecs_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = var.container_name
      image = var.ecr_img_uri
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.task_name}"
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      healthCheck = {
        command      = var.health_check_command
        interval     = 30
        timeout      = 5
        retries      = 3
        startPeriod  = 10
      }
    }
  ])
  lifecycle { ignore_changes = [container_definitions] }
}