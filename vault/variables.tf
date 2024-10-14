variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "monitoring"
}

variable "config_path" {
  description = "Path to the vault configuration files"
  type        = string
}

variable "app_namespace" {
  description = "Environment interacting with Vault(dev, staging, prod)"
  type        = string
  default     = "prod"
}
