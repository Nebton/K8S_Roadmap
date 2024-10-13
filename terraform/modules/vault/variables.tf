variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "vault"
}

variable "config_path" {
  description = "Path to the vault configuration files"
  type        = string
}

variable "app_namespace" {
  description = "App Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
