output "platform_namespace_name" {
  value = kubernetes_namespace.platform.metadata[0].name
}

output "monitoring_namespace_name" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

output "ingress_namespace_name" {
  value = kubernetes_namespace.ingress.metadata[0].name
}

output "cloudflare_namespace_name" {
  value = kubernetes_namespace.cloudflare.metadata[0].name
}
