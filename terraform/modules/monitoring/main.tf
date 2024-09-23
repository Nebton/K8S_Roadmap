terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"  
    }
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = var.environment

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
}

