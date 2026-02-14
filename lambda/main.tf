data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "/tmp/lambda-code.zip"
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.default_tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = var.dlq_arn
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "event_proxy" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 15
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ENDPOINT_URL = var.server_callback_url
      DLQ_URL      = var.dlq_url
    }
  }

  dead_letter_config {
    target_arn = var.dlq_arn
  }

  tags = var.default_tags
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
  tags              = var.default_tags
}
