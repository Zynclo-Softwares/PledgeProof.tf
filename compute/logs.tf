resource "aws_cloudwatch_log_group" "service_logs" {
  name              = "/ecs/${var.task_name}"
  retention_in_days = 7
  tags = var.default_tags
}