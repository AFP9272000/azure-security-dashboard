output "client_id" {
  description = "Client ID of the managed identity (used in Kubernetes service account annotation)"
  value       = azurerm_user_assigned_identity.dashboard.client_id
}

output "principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.dashboard.principal_id
}

output "identity_id" {
  description = "Resource ID of the managed identity"
  value       = azurerm_user_assigned_identity.dashboard.id
}
