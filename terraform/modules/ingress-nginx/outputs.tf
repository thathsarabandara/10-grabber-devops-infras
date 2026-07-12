output "controller_service_name" {
  value       = "ingress-nginx-controller"
  description = "Service name of the ingress controller"
}

output "ingress_namespace" {
  value       = var.ingress_namespace
  description = "Namespace where Ingress Nginx was deployed"
}
