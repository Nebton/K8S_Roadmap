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

  values = [
    yamlencode({
      service = {
        type = "NodePort"
        ports = [
          {
            name       = "status-port"
            port       = 15021
            targetPort = 15021
          },
          {
            name       = "http2"
            port       = 80
            targetPort = 8080
          },
          {
            name       = "https"
            port       = 443
            targetPort = 8443
          },
          {
            name       = "tcp"
            port       = 31400
            targetPort = 31400
          },
          {
            name       = "http-envoy-prom"
            port       = 15020
            targetPort = 15020
          }
        ]
      }
      meshConfig = {
        enablePrometheusMerge = true
      }
      annotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "15020"
        "prometheus.io/path"   = "/stats/prometheus"
      }
    })
  ]
}
resource "kubectl_manifest" "istio_ingress_gateway" {
  yaml_body  =  templatefile( "${var.config_path}/istio-ingress-gateway.yaml", { namespace = var.environment })
  depends_on = [helm_release.istio_ingress]
}

resource "kubectl_manifest" "istio_ingress_servicemonitor" {
  yaml_body  =  templatefile( "${var.config_path}/istio-ingress-servicemonitor.yaml", { namespace = var.environment })
  depends_on = [kubectl_manifest.istio_ingress_gateway]
}

resource "kubectl_manifest" "backend_round_robin" {
  yaml_body  =  templatefile( "${var.config_path}/backend-destination.yaml", {})
  depends_on = [kubectl_manifest.istio_ingress_gateway]
  override_namespace = var.injected_namespace
}

resource "kubectl_manifest" "mtls_policy" {
  yaml_body  =  templatefile( "${var.config_path}/mtls-enable.yaml", {})
  depends_on = [kubectl_manifest.istio_ingress_gateway]
  override_namespace = var.environment
}



