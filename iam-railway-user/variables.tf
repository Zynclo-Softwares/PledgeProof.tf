variable "user_name" {
  description = "IAM user name for the backend's programmatic access."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table the backend can access (index/* is added automatically)."
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket the backend can read/write (/* is added automatically)."
  type        = string
}

variable "dinov2_lambda_arn" {
  description = "ARN of the DINOv2 Lambda the backend may invoke."
  type        = string
}

variable "pdf2img_lambda_arn" {
  description = "ARN of the PDF-to-Image Lambda the backend may invoke."
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito user pool for AdminDeleteUser."
  type        = string
}

variable "default_tags" {
  description = "Tags applied to the IAM user."
  type        = map(string)
  default     = {}
}
