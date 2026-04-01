variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  type        = string
}

variable "aks_cluster_id" {
  description = "AKS cluster resource ID"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Action group for alert notifications
resource "azurerm_monitor_action_group" "security_dashboard" {
  name                = "sec-dashboard-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "secdash"
  tags                = var.tags
}

# Alert: Pod restart count exceeds threshold
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_restarts" {
  name                = "sec-dashboard-pod-restarts"
  resource_group_name = var.resource_group_name
  location            = "eastus"
  description         = "Fires when security-dashboard pod restarts more than 3 times in 15 minutes"
  severity            = 2
  enabled             = true
  tags                = var.tags

  scopes                   = [var.log_analytics_workspace_id]
  evaluation_frequency     = "PT5M"
  window_duration          = "PT15M"
  target_resource_types    = ["Microsoft.OperationalInsights/workspaces"]
  skip_query_validation    = false

  criteria {
    query = <<-KQL
      KubePodInventory
      | where Namespace == "default"
      | where Name startswith "security-dashboard"
      | where PodRestartCount > 0
      | summarize MaxRestarts = max(PodRestartCount) by Name, bin(TimeGenerated, 5m)
      | where MaxRestarts > 3
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    dimension {
      name     = "Name"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.security_dashboard.id]
  }
}

# Alert: Pod not in Ready state
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_not_ready" {
  name                = "sec-dashboard-pod-not-ready"
  resource_group_name = var.resource_group_name
  location            = "eastus"
  description         = "Fires when security-dashboard pod is not in Ready state for more than 5 minutes"
  severity            = 1
  enabled             = true
  tags                = var.tags

  scopes                   = [var.log_analytics_workspace_id]
  evaluation_frequency     = "PT5M"
  window_duration          = "PT10M"
  target_resource_types    = ["Microsoft.OperationalInsights/workspaces"]
  skip_query_validation    = false

  criteria {
    query = <<-KQL
      KubePodInventory
      | where Namespace == "default"
      | where Name startswith "security-dashboard"
      | where PodStatus != "Running"
      | summarize Count = count() by Name, PodStatus, bin(TimeGenerated, 5m)
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    dimension {
      name     = "Name"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.security_dashboard.id]
  }
}

# Alert: Container health check failures (HTTP probe failures)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "health_check_failures" {
  name                = "sec-dashboard-health-failures"
  resource_group_name = var.resource_group_name
  location            = "eastus"
  description         = "Fires when the security-dashboard container fails liveness or readiness probes"
  severity            = 2
  enabled             = true
  tags                = var.tags

  scopes                   = [var.log_analytics_workspace_id]
  evaluation_frequency     = "PT5M"
  window_duration          = "PT15M"
  target_resource_types    = ["Microsoft.OperationalInsights/workspaces"]
  skip_query_validation    = false

  criteria {
     query = <<-KQL
      KubeEvents
      | where Namespace == "default"
      | where Name startswith "security-dashboard"
      | where Reason in ("Unhealthy", "BackOff", "Failed", "FailedMount")
      | summarize ErrorCount = count() by Name, Reason, bin(TimeGenerated, 5m)
      | where ErrorCount > 3
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.security_dashboard.id]
  }
}

output "action_group_id" {
  description = "Action group ID for alert notifications"
  value       = azurerm_monitor_action_group.security_dashboard.id
}
