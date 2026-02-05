# sqs for dlq
resource "aws_sqs_queue" "lambda_dlq" {
    name = var.dlq_name
    delay_seconds = 0
    message_retention_seconds = 604800  # 7 days
    visibility_timeout_seconds = 900  # 15 minutes
    kms_master_key_id                 = "alias/aws/sqs"  # Encrypt! [web:390]
    kms_data_key_reuse_period_seconds = 300      # Efficient crypto
    tags = var.default_tags
}