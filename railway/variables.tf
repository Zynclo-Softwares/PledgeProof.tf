variable "project_name" {
  description = "Railway project name (top-level container)."
  type        = string
}

variable "project_description" {
  description = "Human-readable project description shown in the Railway dashboard."
  type        = string
  default     = "PledgeProof backend (Bun + Elysia)."
}

variable "workspace_id" {
  description = "Railway workspace id. Required when the API token can access more than one workspace; leave empty for single-workspace tokens."
  type        = string
  default     = ""
}

variable "service_name" {
  description = "Railway service name."
  type        = string
  default     = "pledgeproof-server"
}

variable "source_repo" {
  description = "GitHub repo Railway pulls from, as <owner>/<repo>. The Railway GitHub App must already be installed on it."
  type        = string
}

variable "source_repo_branch" {
  description = "Branch Railway watches for auto-deploys."
  type        = string
  default     = "main"
}

variable "root_directory" {
  description = "Docker build context inside the repo. '/' for a single-service repo."
  type        = string
  default     = "/"
}

variable "config_path" {
  description = "Path to the Railway config-as-code file, RELATIVE TO REPO ROOT."
  type        = string
  default     = "railway.json"
}

variable "region" {
  description = "Railway region short code. Available in this workspace: sin (Singapore), pdx (Portland), ams (Amsterdam), sfo (San Francisco), iad (N. Virginia). Prefer the one closest to the AWS region the backend calls — iad is nearest ca-central-1."
  type        = string
  default     = "iad"

  validation {
    condition     = contains(["sin", "pdx", "ams", "sfo", "iad"], var.region)
    error_message = "Region must be one of the workspace's available regions: sin, pdx, ams, sfo, iad."
  }
}

variable "num_replicas" {
  description = "Replicas in the chosen region."
  type        = number
  default     = 1

  validation {
    condition     = var.num_replicas >= 1
    error_message = "num_replicas must be at least 1."
  }
}

variable "service_subdomain" {
  description = "Subdomain for the stable <subdomain>.up.railway.app smoke-test URL. Empty disables it. Must be globally unique within Railway."
  type        = string
  default     = ""
}

variable "custom_domain" {
  description = "Custom domain to register on the service (e.g. api.pledgeproof.zynclo.com). Empty skips it. The Route 53 record is flipped separately during cutover."
  type        = string
  default     = ""
}

variable "variables" {
  description = "Map of environment variables to set on the service. Keys are plain env-var names; values are stored sensitive in state. Pass secret values via the Stack varset, never inline."
  type        = map(string)
  default     = {}
}
