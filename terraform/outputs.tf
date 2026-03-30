output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = module.acr.login_server
}

output "acr_name" {
  description = "ACR name"
  value       = module.acr.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace customer ID (for KQL queries)"
  value       = module.log_analytics.workspace_customer_id
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.cluster_fqdn
}

output "workload_identity_client_id" {
  description = "Client ID of the workload identity managed identity"
  value       = module.workload_identity.client_id
}
