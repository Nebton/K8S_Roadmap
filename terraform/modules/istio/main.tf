# Istio Base
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.23.2"  # Pin the version
  namespace        = var.environment
  create_namespace = true
  timeout          = 900  # 15 minutes

  set {
    name  = "global.istioNamespace"
    value = var.environment 
  }
}

# Istiod
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.23.2"  # Pin the version
  namespace  = var.environment
  timeout    = 900  # 15 minutes

  depends_on = [helm_release.istio_base]

  set {
    name  = "global.hub"
    value = "docker.io/istio"
  }

  set {
    name  = "global.tag"
    value = "1.23.2"
  }
}

# Istio Ingress Gateway
resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = "1.23.2"  
  namespace  = var.environment
  timeout    = 300  

  depends_on = [helm_release.istiod]
  wait       = false

  set {
    name = "service.type"
    value = "NodePort"
  }

}

# Application Namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.environment 
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [helm_release.istiod]
}
