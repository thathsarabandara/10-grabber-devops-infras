output "backup_pvc_name" {
  value       = kubernetes_persistent_volume_claim.backup_pvc.metadata[0].name
  description = "Name of the database backup PVC"
}

output "storage_class_name" {
  value       = var.storage_class_name
  description = "Storage class name used for resources"
}
