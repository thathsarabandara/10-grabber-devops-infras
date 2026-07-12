variable "platform_namespace" {
  type        = string
  description = "Target deployment namespace"
}

variable "storage_class_name" {
  type        = string
  description = "Cluster storage class name"
  default     = "local-path"
}

variable "backup_storage_size" {
  type        = string
  description = "Storage request size for database backups"
  default     = "10Gi"
}

variable "common_labels" {
  type        = map(string)
  description = "Labels to apply to storage resources"
}
