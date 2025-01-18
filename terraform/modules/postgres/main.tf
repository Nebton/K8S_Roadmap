terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

resource "kubernetes_config_map" "postgres_init_scripts" {
  metadata {
    name      = "postgres-init-scripts"
    namespace = var.environment
  }

  data = {
    "init.sql" = <<-EOT

      CREATE ROLE "ro" NOINHERIT;



      CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      INSERT INTO users (username, email) VALUES
      ('john_doe', 'john@example.com'),
      ('jane_smith', 'jane@example.com'),
      ('alice_wonder', 'alice@example.com'),
      ('bob_builder', 'bob@example.com'),
      ('charlie_brown', 'charlie@example.com');

      GRANT SELECT ON ALL TABLES IN SCHEMA public TO "ro";

    EOT
  }
}


resource "helm_release" "postgresql" {
  name       = "postgres"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "16.0.3"
  namespace  = var.environment 
  values     = [file("${path.module}/postgres-values.yaml")]
  set {
    name  = "auth.postgresPassword"
    value = "P@55w0rd" 
  }

  set {
    name  = "auth.database"
    value = "flaskdb"
  }

  # Mount the init scripts
  set {
    name  = "primary.initdb.scriptsConfigMap"
    value = kubernetes_config_map.postgres_init_scripts.metadata[0].name
  }

  # Ensure the init scripts are executed
  set {
    name  = "primary.initdb.user"
    value = "postgres"
  }

  set {
    name  = "primary.initdb.password"
    value = "P@55w0rd" 
  }

  depends_on = [kubernetes_config_map.postgres_init_scripts]
}


