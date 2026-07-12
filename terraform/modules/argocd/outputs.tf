output "argocd_namespace" {
  value       = kubernetes_namespace.argocd.metadata[0].name
  description = "Target namespace where Argo CD is deployed"
}

output "argocd_service_name" {
  value       = "argocd-server"
  description = "Name of the Argo CD Server service"
}
