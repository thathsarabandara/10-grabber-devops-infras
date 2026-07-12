output "bootstrap_configmap_name" {
  value       = kubernetes_config_map.shared_labels.metadata[0].name
  description = "Name of the bootstrap metadata ConfigMap"
}
