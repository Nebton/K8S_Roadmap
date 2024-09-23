resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true

  set {
    name  = "global.istioNamespace"
    value = "istio-system"
  }
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  depends_on = [helm_release.istio_base]

  set {
    name  = "global.hub"
    value = "docker.io/istio"
  }
  set {
    name  = "global.tag"
    value = "1.21.6" 
  }
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"
  depends_on = [helm_release.istiod]

  timeout = 600
}

resource "kubernetes_namespace_v1" "app_namespace" {
  metadata {
    name = var.environment
    labels = {
      "istio-injection" = "enabled"
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}
