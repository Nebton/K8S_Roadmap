# Output the Vault server address
output "vault_address" {
  value = "http://vault.vault.svc.cluster.local:8200"
}

# Output all unseal keys and root token (Be very careful with this in production!)
output "vault_unseal_keys" {
  value     = data.external.vault_init.result.unseal_keys_b64
  sensitive = true
}

output "vault_root_token" {
  value     = data.external.vault_init.result.root_token
  sensitive = true
}
