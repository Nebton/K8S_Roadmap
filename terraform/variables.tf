variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "backend_image" {
  description = "Backend Docker image"
  type        = string
}

variable "backend_versions" {
  description = "List of backend versions to deploy"
  type        = list(string)
  default     = ["v1", "v2"]
}

variable "frontend_image" {
  description = "Frontend Docker image"
  type        = string
}

variable "kube_config_path" {
  description = "Path to kubeconfig file"
  default     = "~/.kube/config"
}

variable "backend_autoscaling_min_replicas" {
  description = "Minimum number of backend replicas"
  type        = number
  default     = 2
}

variable "backend_autoscaling_max_replicas" {
  description = "Maximum number of backend replicas"
  type        = number
  default     = 5
}

variable "backend_autoscaling_cpu_threshold" {
  description = "CPU utilization threshold for scaling"
  type        = number
  default     = 20
}

