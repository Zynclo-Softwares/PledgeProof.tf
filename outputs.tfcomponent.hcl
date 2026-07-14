# Published Stack outputs. Retrieve after apply from the HCP Terraform UI
# (or `terraform stack output`) to drive the DNS cutover.

# <subdomain>.up.railway.app host for each region — use it to smoke-test the
# Railway deploy before flipping DNS.
output "railway_service_domain" {
  type  = map(string)
  value = { for r in var.regions : r => component.railway[r].service_domain }
}

# CNAME target the custom domain must point at. During cutover, flip the
# api.<domain> Route 53 record from the (removed) ALB A-alias to this value.
output "railway_custom_domain_dns_value" {
  type  = map(string)
  value = { for r in var.regions : r => component.railway[r].custom_domain_dns_value }
}

output "railway_project_id" {
  type  = map(string)
  value = { for r in var.regions : r => component.railway[r].project_id }
}
