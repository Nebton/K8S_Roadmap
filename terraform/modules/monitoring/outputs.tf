output "status" {
  value = {
    prometheus     = helm_release.prometheus.status
    node_exporter  = "Deployed"
    servicemonitor = "Deployed"
  }
}
