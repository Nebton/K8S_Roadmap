variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "config_path" {
  description = "Path to postgresql configuration files"
  type        = string
}

