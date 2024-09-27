variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "istio_environment" {
  description = "Environment variable from the istio module"
  type        = string
}

variable "config_path" {
  description = "Path to the app additional configuration files"
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

variable "helm_chart_path" {
  description = "Path to the Helm chart"
  type        = string
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
