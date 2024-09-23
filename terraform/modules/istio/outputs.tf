output "istio_namespace" {
  value       = kubernetes_namespace_v1.app_namespace.metadata[0].name
  description = "The namespace where Istio is installed"
}
