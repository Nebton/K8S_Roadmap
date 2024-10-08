variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "monitoring"
}

variable "config_path" {
  description = "Path to the monitoring configuration files"
  type        = string
}

variable "monitored_namespace" {
  description = "Monitored Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
