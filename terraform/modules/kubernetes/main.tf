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
    labels = {
      istio-injection = "enabled"
    }
  }
}

data "kubectl_file_documents" "env_config" {
  content = file(var.config_path)
}

resource "kubectl_manifest" "env_config" {
  for_each  = data.kubectl_file_documents.env_config.manifests
  yaml_body = each.value
}
