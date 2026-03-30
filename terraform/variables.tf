variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name used for naming and tagging"
  type        = string
  default     = "security-dashboard"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aks_node_vm_size" {
  description = "VM size for AKS node pool"
  type        = string
  default     = "Standard_FX2mds_v2"
}

variable "aks_node_count" {
  description = "Number of nodes in AKS node pool"
  type        = number
  default     = 1
}

variable "dashboard_image_tag" {
  description = "Docker image tag for the security dashboard"
  type        = string
  default     = "v1"
}

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

variable "authorized_ip_ranges" {
  description = "CIDR ranges allowed to access AKS API server"
  type        = list(string)
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}
