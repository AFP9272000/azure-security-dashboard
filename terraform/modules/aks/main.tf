resource "azurerm_kubernetes_cluster" "this" {
  name                = "sec-dashboard-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "sec-dashboard-aks-dns"
  kubernetes_version  = var.kubernetes_version

  # Identity
  identity {
    type = "SystemAssigned"
  }

  # OIDC + Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Disable local admin accounts - enforce Azure AD auth only
  local_account_disabled = true

  # Restrict API server access to specific IPs
  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  # Node pool
  default_node_pool {
    name            = "agentpool"
    node_count      = var.node_count
    vm_size         = var.node_vm_size
    os_disk_size_gb = 128
    zones           = ["1", "2", "3"]

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  # Networking - must specify overlay to match existing cluster
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    load_balancer_sku   = "standard"
  }

  # Monitoring
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Azure Policy addon
  azure_policy_enabled = true

  # Image cleaner
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 168 # weekly

  # Auto-upgrade
  automatic_upgrade_channel = "patch"

  # Azure AD RBAC integration
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = var.tenant_id
  }

  # Maintenance windows
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    duration    = 8
    start_time  = "00:00"
    utc_offset  = "+00:00"
    start_date  = "2026-03-30T00:00:00Z"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    duration    = 8
    start_time  = "00:00"
    utc_offset  = "+00:00"
    start_date  = "2026-03-30T00:00:00Z"
  }

  tags = var.tags
}

# Grant AKS pull access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
