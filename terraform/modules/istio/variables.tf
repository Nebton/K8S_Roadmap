variable "environment" {
  type        = string
  description = "The environment (e.g., dev, staging, prod)"
}

variable "config_path" {
  description = "Path to the istio configuration files"
  type        = string
}
