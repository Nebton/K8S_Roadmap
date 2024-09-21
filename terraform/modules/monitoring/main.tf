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


resource "kubectl_manifest" "node_exporter_deployment" {
  yaml_body  =  templatefile( "${var.config_path}/node-exporter-deployment.yaml", {namespace = var.environment})
  depends_on = [helm_release.prometheus]
}

resource "kubectl_manifest" "node_exporter_service" {
  yaml_body  =  templatefile( "${var.config_path}/node-exporter-service.yaml", {namespace = var.environment})
  depends_on = [helm_release.prometheus, kubectl_manifest.node_exporter_deployment]
}

resource "kubectl_manifest" "flask-app-monitor" {
  yaml_body =  templatefile( "${var.config_path}/flask-app-monitor.yaml", {namespace = var.environment})
  depends_on = [helm_release.prometheus]
}
