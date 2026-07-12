output "platform_namespace" {
  value       = module.namespaces.platform_namespace_name
  description = "Application deployment namespace"
}

output "monitoring_namespace" {
  value       = module.namespaces.monitoring_namespace_name
  description = "Prometheus/Grafana stack namespace"
}

output "ingress_namespace" {
  value       = module.namespaces.ingress_namespace_name
  description = "Ingress Nginx Controller namespace"
}

output "cloudflare_namespace" {
  value       = module.namespaces.cloudflare_namespace_name
  description = "Cloudflared connector daemon namespace"
}

output "ingress_controller_service" {
  value       = module.ingress_nginx.controller_service_name
  description = "NGINX Ingress Controller Service name"
}

output "ingress_internal_origin" {
  value       = locals.ingress_internal_origin
  description = "Target local Ingress Endpoint URL for Cloudflare tunnel mapping"
}

output "grafana_service_name" {
  value       = module.monitoring.grafana_service_name
  description = "Name of Grafana Dashboard Service"
}

output "prometheus_service_name" {
  value       = module.monitoring.prometheus_service_name
  description = "Name of Prometheus Server Service"
}

output "public_hostnames" {
  value = [
    var.dashboard_domain,
    var.api_domain,
    var.grafana_domain,
    var.mqtt_domain
  ]
  description = "Configured public platform domains routed to k3s"
}
