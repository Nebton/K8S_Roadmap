output "istio_namespace" {
  value       = kubernetes_namespace.app_namespace.metadata[0].name
  description = "The namespace where Istio is installed"
}
