output "platform_namespace" {
  value = module.namespaces.platform_namespace_name
}

output "monitoring_namespace" {
  value = module.namespaces.monitoring_namespace_name
}

output "ingress_namespace" {
  value = module.namespaces.ingress_namespace_name
}

output "cloudflare_namespace" {
  value = module.namespaces.cloudflare_namespace_name
}

output "ingress_controller_service" {
  value = module.ingress_nginx.controller_service_name
}

output "ingress_internal_origin" {
  value = locals.ingress_internal_origin
}

output "grafana_service_name" {
  value = module.monitoring.grafana_service_name
}

output "prometheus_service_name" {
  value = module.monitoring.prometheus_service_name
}

output "public_hostnames" {
  value = [
    var.dashboard_domain,
    var.api_domain,
    var.grafana_domain,
    var.mqtt_domain
  ]
}
