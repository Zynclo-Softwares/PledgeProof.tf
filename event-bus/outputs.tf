output "unified_event_bus_id" {
  value = data.aws_cloudwatch_event_bus.unified_bus.id
}

output "unified_event_bus_arn" {
  value = data.aws_cloudwatch_event_bus.unified_bus.arn
}

output "event_bridge_dlq_id" {
  value = aws_sqs_queue.event_bridge_dlq.id
}

output "event_bridge_dlq_arn" {
  value = aws_sqs_queue.event_bridge_dlq.arn
}

