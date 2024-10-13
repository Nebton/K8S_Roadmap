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

provider "kubernetes" {
  config_path = var.kube_config_path
}

provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
  }
}

provider "kubectl" {
  config_path = var.kube_config_path
}

module "kubernetes_resources" {
  source      = "./modules/kubernetes"
  environment = var.environment
  config_path = "${path.root}/../kubernetes/config/${var.environment}-config.yaml"
}

# module "istio" {
#   source      = "./modules/istio"
#   environment = "istio-system"
#   injected_namespace = var.environment
#   config_path = "${path.root}/../kubernetes/istio"
#   depends_on  = [module.kubernetes_resources]
# }

module "application" {
  source         = "./modules/application"
  environment    = var.environment
  istio_environment = "istio-system"
  config_path = "${path.root}/../kubernetes/app"
  backend_image  = var.backend_image
  backend_versions = var.backend_versions
  frontend_image = var.frontend_image
  helm_chart_path = "${path.root}/../helm/k8s-roadmap"
  depends_on  = [module.kubernetes_resources]  
  backend_autoscaling_min_replicas = var.backend_autoscaling_min_replicas
  backend_autoscaling_max_replicas = var.backend_autoscaling_max_replicas
  backend_autoscaling_cpu_threshold = var.backend_autoscaling_cpu_threshold
}

# module "monitoring" {
#   source      = "./modules/monitoring"
#   environment = "monitoring" 
#   monitored_namespace = var.environment
#   config_path = "${path.root}/../kubernetes/monitoring"
#   depends_on  = [module.kubernetes_resources]
# }

module "vault" {
  source      = "./modules/vault"
  environment = "vault" 
  app_namespace = var.environment
  config_path = "${path.root}/../vault"
  depends_on  = [module.kubernetes_resources]
}

module "postgres" {
  source      = "./modules/postgres"
  environment = var.environment 
  config_path = "${path.root}/../helm/postgres"
  depends_on  = [module.kubernetes_resources]
}

# module "logging" {
#   source      = "./modules/logging"
#   environment = "logging" 
#   config_path = "${path.root}/../kubernetes/logging"
#   depends_on  = [module.kubernetes_resources]
# }

