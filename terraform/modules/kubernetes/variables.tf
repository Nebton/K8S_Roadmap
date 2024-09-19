variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "config_path" {
  description = "Path to the environment-specific Kubernetes config file"
  type        = string
}
