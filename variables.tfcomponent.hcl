variable "regions" { type = set(string) }
variable "role_arn" { type = string }
variable "identity_token" {
  type      = string
  ephemeral = true
}
variable "default_tags" {
  type    = map(string)
  default = {}
}

variable "gcp_client_id" {
  description = "GCP OAuth Client ID."
  type        = string
}
variable "gcp_client_secret" {
  description = "GCP OAuth Client Secret."
  type        = string
  sensitive   = true
}

variable "cognito_custom_domain" {
  description = "Custom domain for Cognito OAuth (e.g., auth.pledgeproof.zynclo.com)"
  type        = string
}

variable "apple_services_id" {
  description = "Apple Services ID for Sign In with Apple."
  type        = string
}

variable "apple_team_id" {
  description = "Apple Team ID."
  type        = string
}

variable "apple_key_id" {
  description = "Apple Key ID for Sign In with Apple."
  type        = string
}

variable "apple_private_key" {
  description = "Apple private key (.p8) contents for Sign In with Apple."
  type        = string
  sensitive   = true
}

variable "server_domain_name" {
  description = "Domain for the server ALB (e.g., api.pledgeproof.com)"
  type        = string
}

variable "qstash_token" {
  description = "QStash token for background job scheduling."
  type        = string
  sensitive   = true
}

variable "qstash_current_signing_key" {
  description = "QStash current signing key for webhook verification."
  type        = string
  sensitive   = true
}

variable "qstash_next_signing_key" {
  description = "QStash next signing key for webhook verification."
  type        = string
  sensitive   = true
}

variable "admin_pass" {
  description = "Admin password for the server."
  type        = string
  sensitive   = true
}

variable "github_app_id" {
  description = "GitHub App ID."
  type        = string
}

variable "github_installation_id" {
  description = "GitHub App installation ID."
  type        = string
}

variable "github_private_key" {
  description = "GitHub App private key (PEM contents)."
  type        = string
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "GitHub webhook secret."
  type        = string
  sensitive   = true
}

variable "revenuecat_api_key" {
  description = "RevenueCat API key."
  type        = string
  sensitive   = true
}

variable "enable_dev_table" {
  description = "Create an additional DynamoDB dev table alongside the main table."
  type        = bool
  default     = false
}

# ── DINOv2 Lambda tuning ──
variable "dinov2_memory_size" {
  description = "Memory (MB) for the DINOv2 Lambda function."
  type        = number
  default     = 1536
}
variable "dinov2_timeout" {
  description = "Timeout (seconds) for the DINOv2 Lambda function."
  type        = number
  default     = 30
}
variable "dinov2_image_tag" {
  description = "Container image tag for the DINOv2 Lambda."
  type        = string
  default     = "latest"
}

# ── PDF-to-Image Lambda tuning ──
variable "pdf2img_memory_size" {
  description = "Memory (MB) for the PDF-to-Image Lambda function."
  type        = number
  default     = 512
}
variable "pdf2img_timeout" {
  description = "Timeout (seconds) for the PDF-to-Image Lambda function."
  type        = number
  default     = 30
}
variable "pdf2img_image_tag" {
  description = "Container image tag for the PDF-to-Image Lambda."
  type        = string
  default     = "latest"
}

# ── Compute (ECS) tuning ──
variable "compute_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 256
}
variable "compute_memory" {
  description = "Fargate task memory (MB). Must be compatible with CPU."
  type        = number
  default     = 512
}
variable "compute_max_count" {
  description = "Maximum number of ECS tasks for auto-scaling."
  type        = number
  default     = 1
}

# ── DynamoDB tuning ──
variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode: PAY_PER_REQUEST or PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
}
variable "dynamodb_read_capacity" {
  description = "Provisioned RCUs (only used when billing_mode is PROVISIONED)."
  type        = number
  default     = 0
}
variable "dynamodb_write_capacity" {
  description = "Provisioned WCUs (only used when billing_mode is PROVISIONED)."
  type        = number
  default     = 0
}

# ── Resend Sync Lambda tuning ──
variable "resend_sync_memory_size" {
  description = "Memory (MB) for the Resend Sync Lambda function."
  type        = number
  default     = 256
}
variable "resend_sync_timeout" {
  description = "Timeout (seconds) for the Resend Sync Lambda function."
  type        = number
  default     = 120
}
variable "resend_sync_image_tag" {
  description = "Container image tag for the Resend Sync Lambda."
  type        = string
  default     = "latest"
}
variable "resend_api_key" {
  description = "Resend API key for contact sync."
  type        = string
  sensitive   = true
}
variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID to sync emails from."
  type        = string
  default     = "ca-central-1_NFOMStQGX"
}

locals {
  deployment = var.default_tags["Environment"]
}