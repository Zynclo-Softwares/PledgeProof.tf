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

# ── Railway backend (replaces the ECS/ALB compute stack) ──
variable "railway_token" {
  description = "Railway ACCOUNT or WORKSPACE API token (not a project token). Provisions the Railway project/service."
  type        = string
  sensitive   = true
}
variable "railway_workspace_id" {
  description = "Railway workspace id. Required only if the token can see more than one workspace."
  type        = string
  default     = ""
}
variable "railway_source_repo" {
  description = "GitHub repo Railway deploys the backend from, as <owner>/<repo>."
  type        = string
  default     = "Zynclo-Softwares/PledgeProof.server"
}
variable "railway_source_repo_branch" {
  description = "Branch Railway watches for auto-deploys."
  type        = string
  default     = "main"
}
variable "railway_region" {
  description = "Railway region short code (available: sin, pdx, ams, sfo, iad). iad (N. Virginia) is closest to ca-central-1."
  type        = string
  default     = "iad"
}
variable "railway_num_replicas" {
  description = "Number of Railway replicas."
  type        = number
  default     = 1
}
variable "railway_service_subdomain" {
  description = "Subdomain for the <subdomain>.up.railway.app smoke-test URL. Empty disables it."
  type        = string
  default     = "pledgeproof-api-prod"
}

# ── AWS backend decommission flag (Railway migration) ──
# Phase 1 (false): the legacy ALB + ECS Fargate backend runs ALONGSIDE the new
# Railway service, so the live api domain keeps serving while we smoke-test
# Railway and cut over DNS. Phase 2 (true): tears the ALB + ECS backend down —
# flip this ONLY after DNS is pointed at Railway.
variable "decommission_backend_aws" {
  description = "When true, removes the legacy ALB + ECS Fargate backend. Flip to true only AFTER the DNS cutover to Railway."
  type        = bool
  default     = false
}

# ── Legacy compute (ECS) tuning — used until decommission (see flag above) ──
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