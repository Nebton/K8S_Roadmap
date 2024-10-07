variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "config_path" {
  description = "Path to the ingress-nginx configuration directory"
  type        = string
}
