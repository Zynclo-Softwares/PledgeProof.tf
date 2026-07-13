output "project_id" {
  description = "Railway project id. Dashboard: https://railway.com/project/<id>"
  value       = railway_project.this.id
}

output "service_id" {
  description = "Railway service id."
  value       = railway_service.this.id
}

output "default_environment_id" {
  description = "Default environment id (usually 'production')."
  value       = railway_project.this.default_environment.id
}

output "service_domain" {
  description = "Stable <subdomain>.up.railway.app host for smoke-testing (null if the service domain is disabled)."
  value       = try(railway_service_domain.this[0].domain, null)
}

output "custom_domain_dns_value" {
  description = "CNAME target the custom domain must point at in Route 53 (null if no custom domain). Flip api.<domain> -> this value during cutover."
  value       = try(railway_custom_domain.this[0].dns_record_value, null)
}

output "custom_domain_host_label" {
  description = "Host label Railway reports for the custom domain (null if none)."
  value       = try(railway_custom_domain.this[0].host_label, null)
}
