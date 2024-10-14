terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}


resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.environment
  }
}

resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = var.environment
  create_namespace = false
  version          = "0.28.1"  

 depends_on = [kubernetes_namespace.vault]
}

