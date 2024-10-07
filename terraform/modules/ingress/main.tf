terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"  
    }
  }
}

data "http" "nginx_ingress_manifest" {
  url = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml"
}

resource "kubectl_manifest" "nginx_ingress" {
  yaml_body = data.http.nginx_ingress_manifest.body
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
}

data "kubectl_file_documents" "ingress_yaml" {
  content = file("${var.config_path}/ingress-canary.yaml")
}

resource "kubectl_manifest" "ingress" {
  for_each  = data.kubectl_file_documents.ingress_yaml.manifests
  yaml_body = each.value

  depends_on = [kubernetes_secret.flask_app_tls]
}
