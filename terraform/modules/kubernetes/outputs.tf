output "namespace" {
  value = kubernetes_namespace.app_namespace.metadata[0].name
}
