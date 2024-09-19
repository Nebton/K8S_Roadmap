output "kubernetes_namespace" {
  value = module.kubernetes_resources.namespace
}

output "application_status" {
  value = module.application.status
}

output "monitoring_status" {
  value = module.monitoring.status
}
