locals {
  common_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "resource_group" {
  source = "./modules/resource_group"

  name     = var.project_name
  location = var.location
  tags     = local.common_tags
}

module "acr" {
  source = "./modules/acr"

  acr_name            = "securitydashboardcontainers2"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = local.common_tags
}

module "log_analytics" {
  source = "./modules/log_analytics"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_days      = var.log_retention_days
  tags                = local.common_tags
}

module "defender" {
  source = "./modules/defender"

  subscription_id          = var.subscription_id
  log_analytics_workspace_id = module.log_analytics.workspace_resource_id
}

module "aks" {
  source = "./modules/aks"

  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  acr_id                     = module.acr.acr_id
  log_analytics_workspace_id = module.log_analytics.workspace_resource_id
  node_vm_size               = var.aks_node_vm_size
  node_count                 = var.aks_node_count
  authorized_ip_ranges       = var.authorized_ip_ranges
  tenant_id                  = var.tenant_id
  tags                       = local.common_tags
}

module "workload_identity" {
  source = "./modules/workload_identity"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subscription_id     = var.subscription_id
  aks_oidc_issuer_url = module.aks.oidc_issuer_url
  tags                = local.common_tags
}
