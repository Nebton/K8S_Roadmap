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
      sleep 120
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

output "vault_init_contents" {
  value = jsondecode(data.local_file.vault_init.content)
  sensitive = true
}

locals {
  vault_init = jsondecode(data.local_file.vault_init.content)
}



# resource "null_resource" "vault_unseal" {
#   depends_on = [data.external.vault_init]
#
#   provisioner "local-exec" {
#     command = <<-EOT
#       kubectl exec -n ${var.environment} vault-0 -- vault operator unseal ${data.external.vault_init.result.unseal_keys_b64[0]} &&
#       kubectl exec -n ${var.environment} vault-0 -- vault operator unseal ${data.external.vault_init.result.unseal_keys_b64[1]} &&
#       kubectl exec -n ${var.environment} vault-0 -- vault operator unseal ${data.external.vault_init.result.unseal_keys_b64[2]}
#     EOT
#   }
# }
#
# provider "vault" {
#   address = "http://127.0.0.1:8200"  
#   token   = data.external.vault_init.result.root_token
# }
#
# resource "vault_mount" "kv" {
#   depends_on = [null_resource.vault_unseal]
#   path       = "secret"
#   type       = "kv"
#   options    = { version = "2" }
# }
#
# resource "vault_mount" "db" {
#   depends_on = [null_resource.vault_unseal]
#   path       = "database"
#   type       = "database"
# }# # Configure PostgreSQL connection
# # resource "vault_database_secret_backend_connection" "postgres" {
# #   backend       = vault_mount.db.path
# #   name          = "postgres"
# #   allowed_roles = ["flask-app-role"]
# #
# #   postgresql {
# #     connection_url = "postgresql://{{username}}:{{password}}@postgresql.${kubernetes_namespace.postgresql.metadata[0].name}.svc.cluster.local:5432/flaskdb?sslmode=disable"
# #   }
# # }
# #
# # # Create a role for the database secrets engine
# # resource "vault_database_secret_backend_role" "flask_app_role" {
# #   backend     = vault_mount.db.path
# #   name        = "flask-app-role"
# #   db_name     = vault_database_secret_backend_connection.postgres.name
# #   default_ttl = "1h"
# #   max_ttl     = "24h"
# #
# #   creation_statements = [
# #     "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
# #     "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
# #   ]
# # }
# #
# #
