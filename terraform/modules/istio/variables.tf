variable "environment" {
  type        = string
  description = "The namespace where istio is managed (e.g. istio-system)"
}

variable "config_path" {
  description = "Path to the istio configuration files"
  type        = string
}

variable "injected_namespace" {
  type        = string
  description = "The environment to inject instio in (e.g., dev, staging, prod)"
}


