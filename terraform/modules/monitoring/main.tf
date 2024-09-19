esource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = var.environment

  values = [
    file("${var.config_path}/prometheus-values.yaml")
  ]
}

set {
    name  = "additionalServiceMonitors[0].namespace"
    value = var.environment
  }
  
  set {
    name  = "additionalServiceMonitors[1].namespace"
    value = var.environment
  }

data "kubectl_file_documents" "node_exporter" {
  content = file("${var.config_path}/node-exporter-deployment.yaml")
}

resource "kubectl_manifest" "node_exporter" {
  for_each  = data.kubectl_file_documents.node_exporter.manifests
  yaml_body = each.value
}

data "kubectl_file_documents" "servicemonitor" {
  content = file("${var.config_path}/servicemonitor.yaml")
}

resource "kubectl_manifest" "servicemonitor" {
  for_each  = data.kubectl_file_documents.servicemonitor.manifests
  yaml_body = each.value
}
