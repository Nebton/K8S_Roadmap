terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"  
    }
  }
}

resource "helm_release" "k8s_roadmap" {
  name       = "k8s-roadmap"
  chart      = var.helm_chart_path
  namespace  = var.environment 
  
  values = [
    file("${var.helm_chart_path}/values.yaml")
  ]
  
  set {
    name  = "global.environment"
    value = var.environment
  }
  
  set {
    name  = "backend.image.tag"
    value = split(":", var.backend_image)[1]
  }
  
  set {
    name  = "frontend.image.tag"
    value = split(":", var.frontend_image)[1]
  }
  
  set {
    name  = "backend.replicaCount"
    value = lookup(yamldecode(file("${var.helm_chart_path}/values.yaml")).environments[var.environment], "replicaCount", 1)
  }
  
  set {
    name  = "frontend.replicaCount"
    value = lookup(yamldecode(file("${var.helm_chart_path}/values.yaml")).environments[var.environment], "replicaCount", 1)
  }

  set {
    name  = "backend.autoscaling.enabled"
    value = "true"
  }

  set {
    name  = "backend.autoscaling.minReplicas"
    value = var.backend_autoscaling_min_replicas
  }

  set {
    name  = "backend.autoscaling.maxReplicas"
    value = var.backend_autoscaling_max_replicas
  }

  set {
    name  = "backend.autoscaling.targetCPUUtilizationPercentage"
    value = var.backend_autoscaling_cpu_threshold
  }

  # List of backend versions to deploy
  set {
    name  = "backend.versions"
    value = "{${join(",", var.backend_versions)}}"
  }

}

