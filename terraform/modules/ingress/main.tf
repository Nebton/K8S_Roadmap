terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}


resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    file("${var.config_path}/values.yaml")
  ]
  depends_on = [kubernetes_namespace.ingress_nginx]
}

resource "kubernetes_secret" "flask_app_tls" {
  metadata {
    name      = "flask-app-tls"
    namespace = var.environment
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = file("${var.config_path}/flask-app.com.pem")
    "tls.key" = file("${var.config_path}/flask-app.com-key.pem")
  }
  depends_on = [helm_release.ingress_nginx]
}

data "kubectl_file_documents" "ingress_yaml" {
  content = file("${var.config_path}/ingress-canary.yaml")
}

resource "kubectl_manifest" "ingress" {
  for_each  = data.kubectl_file_documents.ingress_yaml.manifests
  yaml_body = each.value

  depends_on = [kubernetes_secret.flask_app_tls]
}
