variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "monitoring"
}

variable "config_path" {
  description = "Path to the monitoring configuration files"
  type        = string
}
