terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"  
    }
  }
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = var.environment
  labels = {
      istio-injection = "enabled"
    }
  }
}

resource "helm_release" "elastic-search" {
  name       = "prometheus"
  repository = "https://helm.elastic.co" 
  chart      = "elasticsearch"
  namespace  = kubernetes_namespace.logging.metadata[0].name
  values = [
    file("${var.config_path}/elasticsearch-values.yaml")
  ]
  
  replace = true
  force_update  = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.logging]
}

