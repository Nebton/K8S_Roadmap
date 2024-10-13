terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}


# Null provider for local-exec provisioners
provider "null" {}

# External provider for running external commands
provider "external" {}

# Time provider for introducing delays
provider "time" {}



resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = "vault"
  create_namespace = true
  version          = "0.28.1"  

  values = [
      <<-EOT
      server:
        dev:
          enabled: false
        ha:
          enabled: true
        standalone:
          config: |
            ui = true
            listener "tcp" {
              tls_disable = 1
              address = "[::]:8200"
              cluster_address = "[::]:8201"
            }
            storage "file" {
              path = "/vault/data"
            }
      EOT
    ]
}

# Wait for Vault to be ready
resource "time_sleep" "wait_for_vault" {
  depends_on = [helm_release.vault]
  create_duration = "30s"
}

# Initialize Vault with 5 key shares and 3 threshold
data "external" "vault_init" {
  depends_on = [time_sleep.wait_for_vault]
  program = ["sh", "-c", "kubectl exec -n ${kubernetes_namespace.vault.metadata[0].name} vault-0 -- vault operator init -format=json -n 5 -t 3"]
}

# Unseal Vault using 3 of the 5 keys
resource "null_resource" "vault_unseal" {
  depends_on = [data.external.vault_init]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl exec -n ${kubernetes_namespace.vault.metadata[0].name} vault-0 -- vault operator unseal ${data.external.vault_init.result.unseal_keys_b64[0]} &&
      kubectl exec -n ${kubernetes_namespace.vault.metadata[0].name} vault-0 -- vault operator unseal ${data.external.vault_init.result.unseal_keys_b64[1]} &&
      kubectl exec -n ${kubernetes_namespace.vault.metadata[0].name} vault-0 -- vault operator unseal ${data.external.vault_init.result.unseal_keys_b64[2]}
    EOT
  }
}

# Configure Vault provider
provider "vault" {
  address = "http://127.0.0.1:8200"  
  token   = data.external.vault_init.result.root_token
}

# Enable KV secrets engine
resource "vault_mount" "kv" {
  depends_on = [null_resource.vault_unseal]
  path       = "secret"
  type       = "kv"
  options    = { version = "2" }
}

# Enable database secrets engine
resource "vault_mount" "db" {
  depends_on = [null_resource.vault_unseal]
  path       = "database"
  type       = "database"
}

# # Configure PostgreSQL connection
# resource "vault_database_secret_backend_connection" "postgres" {
#   backend       = vault_mount.db.path
#   name          = "postgres"
#   allowed_roles = ["flask-app-role"]
#
#   postgresql {
#     connection_url = "postgresql://{{username}}:{{password}}@postgresql.${kubernetes_namespace.postgresql.metadata[0].name}.svc.cluster.local:5432/flaskdb?sslmode=disable"
#   }
# }
#
# # Create a role for the database secrets engine
# resource "vault_database_secret_backend_role" "flask_app_role" {
#   backend     = vault_mount.db.path
#   name        = "flask-app-role"
#   db_name     = vault_database_secret_backend_connection.postgres.name
#   default_ttl = "1h"
#   max_ttl     = "24h"
#
#   creation_statements = [
#     "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
#     "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
#   ]
# }
#
#
