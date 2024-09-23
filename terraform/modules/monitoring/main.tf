terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"  
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.environment
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  values = [
    file("${var.config_path}/prometheus-values.yaml")
  ]
  
  set {
    name  = "additionalServiceMonitors[0].namespace"
    value = var.environment
  }
  
  set {
    name  = "additionalServiceMonitors[1].namespace"
    value = var.environment
  }

  replace = true
  force_update  = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.monitoring]
}
