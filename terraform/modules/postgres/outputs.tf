# Output the PostgreSQL connection details
output "postgres_connection_info" {
  value = {
    host     = "${helm_release.postgresql.name}-postgresql.${helm_release.postgresql.namespace}.svc.cluster.local"
    port     = 5432
    database = "flaskdb"
    username = "postgres"  # Default username for Bitnami PostgreSQL chart
  }
  sensitive = true
}

