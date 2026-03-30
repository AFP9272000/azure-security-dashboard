variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "acr_id" {
  description = "ACR resource ID for pull access"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  type        = string
}

variable "node_vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_FX2mds_v2"
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
  default     = 1
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34.3"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "authorized_ip_ranges" {
  description = "List of authorized IP CIDR ranges for API server access"
  type        = list(string)
  default     = []
}

variable "tenant_id" {
  description = "Azure AD tenant ID for RBAC integration"
  type        = string
}
