output "postgres_password" {
  value     = module.postgres.postgres_password
  sensitive = true
}

output "postgres_namespace" {
  value = module.postgres.postgres_namespace
}

output "vault_namespace" {
  value = module.vault.vault_namespace
}

