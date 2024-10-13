terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}
resource "helm_release" "postgresql" {
  name       = "postgres"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = var.environment 
  set {
    name  = "auth.postgresPassword"
    value = "P@55w0rd" 
  }

  set {
    name  = "auth.database"
    value = "flaskdb"
  }

}


