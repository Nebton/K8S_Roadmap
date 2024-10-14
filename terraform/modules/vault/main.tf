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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
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


resource "null_resource" "vault_init" {
  depends_on = [helm_release.vault]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      sleep 30
      kubectl exec -n ${var.environment} vault-0 -- vault operator init -format=json -n 5 -t 3 > vault_init.json
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f vault_init.json"
  }
}

data "local_file" "vault_init" {
  depends_on = [null_resource.vault_init]
  filename   = "${path.root}/vault_init.json"
}

locals {
  vault_init = jsondecode(data.local_file.vault_init.content)
}


resource "null_resource" "vault_unseal" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl exec -n ${var.environment} vault-0 -- vault operator unseal ${local.vault_init.unseal_keys_b64[0]}
      kubectl exec -n ${var.environment} vault-0 -- vault operator unseal ${local.vault_init.unseal_keys_b64[1]}
      kubectl exec -n ${var.environment} vault-0 -- vault operator unseal ${local.vault_init.unseal_keys_b64[2]}
    EOT
  }
}

# Store root token securely (use a more secure method in production)
resource "kubernetes_secret" "vault_root_token" {
  metadata {
    name = "vault-root-token"
    namespace = var.environment
  }

  data = {
    token = local.vault_init.root_token
  }

  type = "Opaque"
}


# Get Kubernetes configuration details
resource "null_resource" "get_k8s_config" {
  depends_on = [null_resource.vault_unseal]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}' > kube_host.txt
      kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode > kube_ca_cert.txt
      kubectl create token vault-auth -n default > sa_token.txt
    EOT
  }
}

# Read the Kubernetes configuration details into local variables
data "local_file" "kube_host" {
  depends_on = [null_resource.get_k8s_config]
  filename   = "${path.root}/kube_host.txt"
}

data "local_file" "kube_ca_cert" {
  depends_on = [null_resource.get_k8s_config]
  filename   = "${path.root}/kube_ca_cert.txt"
}

data "local_file" "sa_token" {
  depends_on = [null_resource.get_k8s_config]
  filename   = "${path.root}/sa_token.txt"
}

# Configure Vault Kubernetes auth
resource "null_resource" "configure_vault_k8s_auth" {
  depends_on = [null_resource.get_k8s_config]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Configuring Vault Kubernetes auth..."
      echo "Kubernetes Host: ${data.local_file.kube_host.content}"
      kubectl exec -n ${var.environment} vault-0 -- /bin/sh -c "
        vault login ${local.vault_init.root_token}
        vault auth enable kubernetes
        vault write auth/kubernetes/config \
          kubernetes_host='${data.local_file.kube_host.content}' \
          kubernetes_ca_cert='${data.local_file.kube_ca_cert.content}' \
          token_reviewer_jwt='${data.local_file.sa_token.content}'
      "
    EOT
  }
}

# Clean up temporary files
resource "null_resource" "cleanup_k8s_config_files" {
  depends_on = [null_resource.configure_vault_k8s_auth]

  provisioner "local-exec" {
    command = <<-EOT
      rm -f kube_host.txt kube_ca_cert.txt sa_token.txt
    EOT
  }
}

# Set up port forwarding
resource "null_resource" "vault_port_forward" {
  provisioner "local-exec" {
    command = "kubectl port-forward -n ${var.environment} service/vault 8200:8200 &"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "pkill -f 'kubectl port-forward -n ${var.environment} service/vault 8200:8200'"
  }

  # Wait for port forwarding to be established
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# Vault provider configuration
provider "vault" {
  address = "http://127.0.0.1:8200"
  token   = local.vault_init.root_token
}

# Enable KV2 secrets engine
resource "vault_mount" "kv" {
  depends_on = [null_resource.vault_port_forward]
  path        = "kv"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

# Create a secret in kv/frontend with the 3rd unseal key
resource "vault_kv_secret_v2" "frontend" {
  mount               = vault_mount.kv.path
  name                = "frontend"
  delete_all_versions = true
  data_json = jsonencode({
    k3y = local.vault_init.unseal_keys_b64[2]
  })
}

# Create a policy to allow reading the frontend secret
resource "vault_policy" "frontend" {
  name = "frontend"

  policy = <<EOT
path "kv/data/frontend" {
  capabilities = ["read"]
}
EOT
}

# Create a Kubernetes auth role for the frontend service account
resource "vault_kubernetes_auth_backend_role" "frontend" {
  backend                          = "kubernetes"
  role_name                        = "frontend"
  bound_service_account_names      = ["frontend-sa"]
  bound_service_account_namespaces = [var.environment]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.frontend.name]
}
