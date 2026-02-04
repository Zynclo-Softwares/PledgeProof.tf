# using the default event bus for automatic events from services
data "aws_cloudwatch_event_bus" "default_bus" {
  name = "default"
}
