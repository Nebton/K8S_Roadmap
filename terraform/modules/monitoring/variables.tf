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

variable "helm_chart_path" {
  description = "Path to the Helm chart"
  type        = string
}
