variable "enable_monitoring" {
  type        = bool
  description = "Deploy monitoring stack flag"
  default     = true
}

variable "monitoring_namespace" {
  type        = string
  description = "Target namespace for prometheus Helm stack"
}

variable "platform_namespace" {
  type        = string
  description = "Application platform namespace"
}

variable "kube_prometheus_stack_version" {
  type        = string
  description = "Helm release version constraint"
  default     = "60.0.1"
}

variable "storage_class_name" {
  type        = string
  description = "PV Storage class provider name"
  default     = "local-path"
}

variable "prometheus_storage_size" {
  type        = string
  description = "Size of prometheus storage PVC"
  default     = "10Gi"
}

variable "grafana_storage_size" {
  type        = string
  description = "Size of Grafana configuration storage PVC"
  default     = "2Gi"
}

variable "prometheus_retention" {
  type        = string
  description = "Prometheus data retention interval string"
  default     = "7d"
}

variable "common_labels" {
  type        = map(string)
  description = "Labels to apply to the resource stack"
}
