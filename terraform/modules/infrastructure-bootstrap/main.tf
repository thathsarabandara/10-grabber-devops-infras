resource "kubernetes_config_map" "shared_labels" {
  metadata {
    name      = "platform-bootstrap-metadata"
    namespace = var.platform_namespace
    labels    = var.common_labels
  }

  data = {
    platform_name = var.platform_name
    managed_by    = "terraform"
  }
}
