variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "backend_image" {
  description = "Backend Docker image"
  type        = string
}

variable "frontend_image" {
  description = "Frontend Docker image"
  type        = string
}

variable "kube_config_path" {
  description = "Path to kubeconfig file"
  default     = "~/.kube/config"
}
