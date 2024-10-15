# Output the PostgreSQL connection details
output "postgres_connection_info" {
  value = {
    host     = "${helm_release.postgresql.name}-postgresql.${helm_release.postgresql.namespace}.svc.cluster.local"
    port     = 5432
    database = "flaskdb"
    username = "postgres"  
  }
  sensitive = true
}

output "postgres_password" {
  value     = "P@55w0rd"
  sensitive = true
}
