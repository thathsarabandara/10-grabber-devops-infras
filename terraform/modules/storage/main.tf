resource "kubernetes_persistent_volume_claim" "backup_pvc" {
  metadata {
    name      = "backup-pvc"
    namespace = var.platform_namespace
    labels    = var.common_labels
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class_name

    resources {
      requests = {
        storage = var.backup_storage_size
      }
    }
  }
}
