output "status" {
  value = {
    elasticsearch = helm_release.elastic-search.status
  }
}

