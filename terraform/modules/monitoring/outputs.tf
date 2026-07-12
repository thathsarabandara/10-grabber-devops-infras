output "grafana_service_name" {
  value       = var.enable_monitoring ? "prometheus-grafana" : ""
  description = "Service name of Grafana dashboard server"
}

output "prometheus_service_name" {
  value       = var.enable_monitoring ? "prometheus-kube-prometheus-prometheus" : ""
  description = "Service name of Prometheus server"
}
