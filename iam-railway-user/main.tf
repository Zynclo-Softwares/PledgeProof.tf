terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Programmatic IAM user for the backend now that it runs OFF AWS (on Railway).
#
# On ECS Fargate the container assumed an ECS task role and the AWS SDK picked
# up temporary credentials automatically. Off AWS there is no task role, so the
# backend authenticates with these long-lived access keys, injected as
# AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY env vars on the Railway service.
#
# The policy below mirrors the old ECS task role (terraform/compute/task.tf)
# exactly: DynamoDB, S3, Bedrock, Lambda invoke, Cognito AdminDeleteUser.
# ---------------------------------------------------------------------------
resource "aws_iam_user" "this" {
  name = var.user_name
  tags = var.default_tags
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "backend" {
  statement {
    sid    = "DynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/index/*",
    ]
  }

  statement {
    sid    = "S3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*",
    ]
  }

  statement {
    sid     = "Bedrock"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:aws:bedrock:*::foundation-model/anthropic.*",
      "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.*",
    ]
  }

  statement {
    sid       = "LambdaInvoke"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [var.dinov2_lambda_arn, var.pdf2img_lambda_arn]
  }

  statement {
    sid       = "Cognito"
    effect    = "Allow"
    actions   = ["cognito-idp:AdminDeleteUser"]
    resources = [var.cognito_user_pool_arn]
  }
}

resource "aws_iam_user_policy" "backend" {
  name   = "${var.user_name}-backend"
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.backend.json
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}
