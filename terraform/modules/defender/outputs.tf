output "containers_pricing_tier" {
  description = "Defender for Containers pricing tier"
  value       = azurerm_security_center_subscription_pricing.containers.tier
}
