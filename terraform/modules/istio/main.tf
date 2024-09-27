terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"  
    }
  }
}

# Application Namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.environment 
  }
}

# Istio Base
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.23.2"  # Pin the version
  namespace        = var.environment
  timeout          = 300 

  depends_on = [kubernetes_namespace.app_namespace]

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
  version    = "1.23.2"  
  namespace  = var.environment
  timeout    = 900  

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
    name  = "service.type"
    value = "NodePort"
  }

  # Enable Prometheus scraping
  set {
    name  = "meshConfig.enablePrometheusMerge"
    value = "true"
  }

  # Expose Prometheus metrics port
  set {
    name  = "service.ports[4].name"
    value = "http-envoy-prom"
  }
  set {
    name  = "service.ports[4].port"
    value = "15020"
  }
  set {
    name  = "service.ports[4].targetPort"
    value = "15020"
  }

  # Set annotations for Prometheus scraping
  set {
    name  = "annotations.prometheus\\.io/scrape"
    value = "true"
  }
  set {
    name  = "annotations.prometheus\\.io/port"
    value = "15020"
  }
  set {
    name  = "annotations.prometheus\\.io/path"
    value = "/stats/prometheus"
  }
}

resource "kubectl_manifest" "istio_ingress_gateway" {
  yaml_body  =  templatefile( "${var.config_path}/istio-ingress-gateway.yaml")
  depends_on = [helm_release.istio_ingress]
}

resource "kubectl_manifest" "istio_ingress_servicemonitor" {
  yaml_body  =  templatefile( "${var.config_path}/istio-ingress-servicemonitor.yaml")
  depends_on = [kubectl_manifest.istio_ingress_gateway]
}

resource "kubectl_manifest" "frontend_backend_route" {
  yaml_body  =  templatefile( "${var.config_path}/frontend-backend-route.yaml")
  depends_on = [kubectl_manifest.istio_ingress_servicemonitor]
}


