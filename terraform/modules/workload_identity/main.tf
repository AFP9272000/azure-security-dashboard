# Managed Identity for the dashboard workload
resource "azurerm_user_assigned_identity" "dashboard" {
  name                = "sec-dashboard-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Federated credential linking the Kubernetes service account to the managed identity
resource "azurerm_federated_identity_credential" "dashboard" {
  name                = "sec-dashboard-federated"
  parent_id           = azurerm_user_assigned_identity.dashboard.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:default:sec-dashboard-sa"
}

# Role assignments - what the dashboard identity can access

# Reader on the subscription (resource inventory, general read access)
resource "azurerm_role_assignment" "subscription_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.dashboard.principal_id
}

# Security Reader (Defender for Cloud alerts, recommendations, secure score)
resource "azurerm_role_assignment" "security_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Security Reader"
  principal_id         = azurerm_user_assigned_identity.dashboard.principal_id
}

# Log Analytics Reader (KQL queries against the workspace)
resource "azurerm_role_assignment" "log_analytics_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_user_assigned_identity.dashboard.principal_id
}

# Monitoring Reader (metrics and diagnostic data)
resource "azurerm_role_assignment" "monitoring_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_user_assigned_identity.dashboard.principal_id
}
