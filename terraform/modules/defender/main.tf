# Foundational CSPM
resource "azurerm_security_center_subscription_pricing" "cspm" {
  tier          = "Standard"
  resource_type = "CloudPosture"
}

# Defender for Containers
resource "azurerm_security_center_subscription_pricing" "containers" {
  tier          = "Standard"
  resource_type = "Containers"

  extension {
    name = "ContainerSensor"
    additional_extension_properties = {
      AntiMalwareEnabled    = "False"
      SecurityGatingEnabled = "True"
    }
  }

  extension {
    name = "AgentlessVmScanning"
    additional_extension_properties = {
      ExclusionTags = jsonencode([])
    }
  }

  extension {
    name = "AgentlessDiscoveryForKubernetes"
  }

  extension {
    name = "ContainerIntegrityContribution"
  }

  extension {
    name = "ContainerRegistriesVulnerabilityAssessments"
  }
}

# Diagnostic setting: send subscription Activity Log to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "subscription" {
  name                       = "sec-dashboard-diagnostics"
  target_resource_id         = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Alert"
  }
}
