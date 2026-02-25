# ── DINOv2-small ONNX — Container Lambda ────────────────────────────────────
#
# Docker image Lambda for image embedding & cosine comparison.
# Invoked directly by the Elysia server via AWS SDK (InvokeCommand).
# ────────────────────────────────────────────────────────────────────────────

# ── ECR Repository ──────────────────────────────────────────────────────────

resource "aws_ecr_repository" "dinov2" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = var.default_tags
}

resource "aws_ecr_lifecycle_policy" "dinov2" {
  repository = aws_ecr_repository.dinov2.name

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

# ── IAM Role ────────────────────────────────────────────────────────────────

resource "aws_iam_role" "dinov2_lambda" {
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

resource "aws_iam_role_policy" "dinov2_lambda" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.dinov2_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ── Lambda Function (Container Image) ──────────────────────────────────────

resource "aws_lambda_function" "dinov2" {
  function_name = var.function_name
  role          = aws_iam_role.dinov2_lambda.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.dinov2.repository_url}:${var.image_tag}"
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = ["x86_64"]

  environment {
    variables = {
      MODEL_PATH = "/opt/model/dinov2_vits14.onnx"
    }
  }

  tags = var.default_tags

  depends_on = [aws_ecr_repository.dinov2]
}

# ── CloudWatch Log Group ───────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "dinov2" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
  tags              = var.default_tags
}
