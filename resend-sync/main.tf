# ── Resend Contact Sync — Scheduled Container Lambda ────────────────────────
#
# Syncs Cognito user emails → Resend audience (unique contacts only).
# Invoked 3× daily by EventBridge Scheduler (8 AM, 1 PM, 8 PM ET).
# ────────────────────────────────────────────────────────────────────────────

# ── ECR Repository ──────────────────────────────────────────────────────────

resource "aws_ecr_repository" "resend_sync" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = var.default_tags
}

resource "aws_ecr_lifecycle_policy" "resend_sync" {
  repository = aws_ecr_repository.resend_sync.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only last 3 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
      action = { type = "expire" }
    }]
  })
}

# ── IAM Role — Lambda ──────────────────────────────────────────────────────

resource "aws_iam_role" "resend_sync_lambda" {
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

resource "aws_iam_role_policy" "resend_sync_lambda" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.resend_sync_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CloudWatchLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid      = "CognitoListUsers"
        Effect   = "Allow"
        Action   = ["cognito-idp:ListUsers"]
        Resource = "arn:aws:cognito-idp:*:*:userpool/${var.cognito_user_pool_id}"
      }
    ]
  })
}

# ── Lambda Function (Container Image) ──────────────────────────────────────

resource "aws_lambda_function" "resend_sync" {
  function_name = var.function_name
  role          = aws_iam_role.resend_sync_lambda.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.resend_sync.repository_url}:${var.image_tag}"
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = ["x86_64"]

  environment {
    variables = {
      RESEND_API_KEY       = var.resend_api_key
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
    }
  }

  tags = var.default_tags

  depends_on = [aws_ecr_repository.resend_sync]
}

# ── CloudWatch Log Group ───────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "resend_sync" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
  tags              = var.default_tags
}

# ── EventBridge Scheduler — IAM Role ───────────────────────────────────────

resource "aws_iam_role" "scheduler" {
  name = "${var.function_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })

  tags = var.default_tags
}

resource "aws_iam_role_policy" "scheduler" {
  name = "${var.function_name}-scheduler-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = aws_lambda_function.resend_sync.arn
    }]
  })
}

# ── EventBridge Schedules — 8 AM, 1 PM, 8 PM ──────────────────────────────

resource "aws_scheduler_schedule_group" "resend_sync" {
  name = "${var.function_name}-schedules"
  tags = var.default_tags
}

resource "aws_scheduler_schedule" "morning" {
  name       = "${var.function_name}-morning"
  group_name = aws_scheduler_schedule_group.resend_sync.name

  schedule_expression          = "cron(0 8 * * ? *)"
  schedule_expression_timezone = var.schedule_timezone

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 15
  }

  target {
    arn      = aws_lambda_function.resend_sync.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ trigger = "morning" })
  }
}

resource "aws_scheduler_schedule" "afternoon" {
  name       = "${var.function_name}-afternoon"
  group_name = aws_scheduler_schedule_group.resend_sync.name

  schedule_expression          = "cron(0 13 * * ? *)"
  schedule_expression_timezone = var.schedule_timezone

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 15
  }

  target {
    arn      = aws_lambda_function.resend_sync.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ trigger = "afternoon" })
  }
}

resource "aws_scheduler_schedule" "evening" {
  name       = "${var.function_name}-evening"
  group_name = aws_scheduler_schedule_group.resend_sync.name

  schedule_expression          = "cron(0 20 * * ? *)"
  schedule_expression_timezone = var.schedule_timezone

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 15
  }

  target {
    arn      = aws_lambda_function.resend_sync.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ trigger = "evening" })
  }
}
