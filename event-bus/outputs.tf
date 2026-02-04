output "default_event_bus" {
  value = data.aws_cloudwatch_event_bus.default_bus.id
}