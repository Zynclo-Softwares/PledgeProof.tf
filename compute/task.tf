# # IAM Roles (required for Fargate)
# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "pledgeproof-task-execution"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# # Task Definition (Fargate monolith)
# resource "aws_ecs_task_definition" "pledgeproof" {
#   family                   = "pledgeproof"
#   network_mode             = "awsvpc"              # Fargate required
#   requires_compatibilities = ["FARGATE"]           # Fargate launch
#   cpu                      = 256                   # 0.25 vCPU
#   memory                   = 512                   # 0.5GB (dev/low traffic)

#   execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

#   container_definitions = jsonencode([{
#     name  = "pledgeproof"                          # Matches load_balancer.container_name
#     image = "123456789012.dkr.ecr.ca-central-1.amazonaws.com/pledgeproof:latest"  # Your ECR URI:tag
#     essential = true
#     portMappings = [{
#       containerPort = 80                          
#       protocol      = "tcp"
#     }]
#     logConfiguration = {
#       logDriver = "awslogs"
#       options = {
#         awslogs-group         = "/ecs/pledgeproof"
#         awslogs-region        = "ca-central-1"
#         awslogs-stream-prefix = "ecs"
#       }
#     }
#     healthCheck = {
#       command = ["CMD-SHELL", "curl -f http://localhost/health || exit 1"]
#       interval    = 30
#       timeout     = 5
#       retries     = 3
#     }
#   }])
#   tags = var.default_tags
# }
