terraform {
  required_version = ">= 1.6"

  required_providers {
    railway = {
      source  = "terraform-community-providers/railway"
      version = "~> 0.5"
    }
  }
}

# ---------------------------------------------------------------------------
# Project — top-level container in Railway. One project holds the backend
# service, its environment, and its variables. Created private.
# ---------------------------------------------------------------------------
resource "railway_project" "this" {
  name        = var.project_name
  description = var.project_description
  private     = true

  # Required when the API token can see more than one workspace.
  workspace_id = var.workspace_id != "" ? var.workspace_id : null
}

# ---------------------------------------------------------------------------
# Service — wires the project to the GitHub repo and pins region + replicas.
# Build settings (Dockerfile path, healthcheck, restart policy) live in the
# repo's railway.json (config_path) so the deploy contract stays with the app.
#
# NOTE: the Railway GitHub App must already be installed on `source_repo`
# (one-time manual step in the Railway dashboard). The provider does NOT
# expose Watch Paths — every push to `source_repo_branch` redeploys.
# ---------------------------------------------------------------------------
resource "railway_service" "this" {
  name       = var.service_name
  project_id = railway_project.this.id

  source_repo        = var.source_repo
  source_repo_branch = var.source_repo_branch

  # root_directory is the Docker build context; config_path is resolved
  # against the REPO ROOT (not root_directory). For a single-service repo
  # both point at the repo root.
  root_directory = var.root_directory
  config_path    = var.config_path

  regions = [
    {
      region       = var.region
      num_replicas = var.num_replicas
    },
  ]
}

# ---------------------------------------------------------------------------
# Environment variables — atomic upsert of the whole set in ONE GraphQL call
# (one redeploy). Using per-variable resources instead would fire N redeploys
# and trip Railway's deploy rate limit. The map is sensitive so values are
# masked in plan/state; pass secrets via the Stack's varset, never inline.
# ---------------------------------------------------------------------------
resource "railway_variable_collection" "env" {
  environment_id = railway_project.this.default_environment.id
  service_id     = railway_service.this.id

  variables = [
    for name, value in var.variables : {
      name  = name
      value = value
    }
  ]
}

# ---------------------------------------------------------------------------
# Service domain — stable <subdomain>.up.railway.app URL. Handy for smoke-
# testing the deploy BEFORE the custom domain's DNS/TLS finish provisioning.
# Gated on a non-empty subdomain so it can be turned off.
# ---------------------------------------------------------------------------
resource "railway_service_domain" "this" {
  count = var.service_subdomain != "" ? 1 : 0

  subdomain      = var.service_subdomain
  environment_id = railway_project.this.default_environment.id
  service_id     = railway_service.this.id
}

# ---------------------------------------------------------------------------
# Custom domain — e.g. api.pledgeproof.zynclo.com. Registering it here tells
# Railway to expect the host and to provision Let's Encrypt TLS once the DNS
# CNAME resolves to `dns_record_value` (see outputs). The actual DNS record
# lives in Route 53 and is flipped during cutover — intentionally NOT managed
# here so the A-alias -> CNAME swap can be done as a single atomic Route 53
# change-batch without a cross-resource ordering conflict.
# ---------------------------------------------------------------------------
resource "railway_custom_domain" "this" {
  count = var.custom_domain != "" ? 1 : 0

  domain         = var.custom_domain
  environment_id = railway_project.this.default_environment.id
  service_id     = railway_service.this.id
}
