terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"  
    }
  }
}

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
  version          = "1.23.2"
  namespace        = var.environment
  timeout          = 300 
  depends_on       = [kubernetes_namespace.app_namespace]
  values           = [file("${path.module}/istio-values.yaml")]
  
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
  timeout    = 600  # Reduced from 900
  depends_on = [helm_release.istio_base]
  values     = [file("${path.module}/istio-values.yaml")]
  
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
  wait       = true 
  values     = [
    file("${path.module}/istio-values.yaml"),
    yamlencode({
      gateways = {
        istio-ingressgateway = {
          autoscaleEnabled = false
          replicaCount = 1
          service = {
            type = "LoadBalancer"
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
        }
      }
    })
  ]
}

resource "kubernetes_secret" "flask_app_tls" {
  metadata {
    name      = "flask-app-tls"
    namespace = var.environment
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = file("${path.module}/tls/flask-app.com.pem")
    "tls.key" = file("${path.module}/tls/flask-app.com-key.pem")
  }
  depends_on = [helm_release.istio_ingress]
}

resource "kubectl_manifest" "istio_ingress_gateway" {
  yaml_body  =  templatefile( "${path.module}/traffic/istio-ingress-gateway.yaml", { namespace = var.environment })
  depends_on = [kubernetes_secret.flask_app_tls]
}

resource "kubectl_manifest" "backend_round_robin" {
  yaml_body  =  templatefile( "${path.module}/traffic/backend-destination.yaml", {})
  depends_on = [kubectl_manifest.istio_ingress_gateway]
  override_namespace = var.injected_namespace
}

resource "kubectl_manifest" "mtls_policy" {
  yaml_body  =  templatefile( "${path.module}/tls/mtls-enable.yaml", {})
  depends_on = [kubectl_manifest.istio_ingress_gateway]
  override_namespace = var.environment
}

# Virtual service to control traffic between v1 and v2
resource "kubectl_manifest" "frontend_backend_route" {
  yaml_body  =  templatefile( "${path.module}/traffic/frontend-backend-route.yaml", {})
  depends_on = [kubernetes_secret.flask_app_tls]
  override_namespace = var.injected_namespace
}

# Destination rule to label v1 and v2 subsets
resource "kubectl_manifest" "split_traffic" {
  yaml_body  =  templatefile( "${path.module}/traffic/split-traffic.yaml", {})
  depends_on = [kubernetes_secret.flask_app_tls]
  override_namespace = var.injected_namespace
}


## Disable TLS on backend metrics port
resource "kubectl_manifest" "backend_peer_authentication" {
  yaml_body  =  templatefile( "${path.module}/traffic/backend-peer-authentication.yaml", {})
  depends_on = [kubectl_manifest.mtls_policy]
  override_namespace = var.injected_namespace
}

resource "kubectl_manifest" "default_deny_policy" {
  yaml_body  =  templatefile( "${path.module}/authz/default-deny.yaml", {})
  depends_on = [kubectl_manifest.mtls_policy]
  override_namespace = var.environment
}

resource "kubectl_manifest" "allow_ingress" {
  yaml_body  =  templatefile( "${path.module}/authz/allow-ingress.yaml", {})
  depends_on = [kubectl_manifest.mtls_policy]
  override_namespace = var.injected_namespace
}

resource "kubectl_manifest" "allow_ingress_to_apps" {
  yaml_body  =  templatefile( "${path.module}/authz/allow-ingress-apps.yaml", {})
  depends_on = [kubectl_manifest.mtls_policy]
  override_namespace = var.environment
}

resource "kubectl_manifest" "allow_traffic_to_backend" {
  yaml_body  =  templatefile( "${path.module}/authz/backend-allow.yaml", {})
  depends_on = [kubectl_manifest.mtls_policy]
  override_namespace = var.injected_namespace
}

resource "kubectl_manifest" "allow_admin_full_access" {
  yaml_body  =  templatefile( "${path.module}/authz/admin-allow.yaml", {})
  depends_on = [kubectl_manifest.mtls_policy]
  override_namespace = var.injected_namespace
}

resource "kubectl_manifest" "allow_front_back_communication" {
  yaml_body  =  templatefile( "${path.module}/authz/front-back.yaml", {})
  depends_on = [kubectl_manifest.mtls_policy]
  override_namespace = var.injected_namespace
}

resource "kubectl_manifest" "ratelimit_config" {
  yaml_body  =  templatefile( "${path.module}/rate-limit/ratelimit-config.yaml", {})
  override_namespace = var.injected_namespace
}

resource "kubectl_manifest" "ratelimit_envoy_filter" {
  yaml_body  =  templatefile( "${path.module}/rate-limit/filter-ratelimit.yaml", {})
  override_namespace = var.environment
}

resource "kubectl_manifest" "ratelimit_service" {
  yaml_body  =  templatefile( "${path.module}/rate-limit/ratelimit-service.yaml", {})
  override_namespace = var.injected_namespace
}

resource "kubectl_manifest" "ratelimit_svc_filter" {
  yaml_body  =  templatefile( "${path.module}/rate-limit/filter-ratelimit-svc.yaml", {})
  override_namespace = var.environment
}

