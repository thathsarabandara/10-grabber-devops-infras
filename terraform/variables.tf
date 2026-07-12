variable "platform_name" {
  type        = string
  description = "Name of the platform deployment"
  default     = "grabber-platform"
}

variable "environment" {
  type        = string
  description = "Execution environment (e.g. local-vm, dev, prod)"
  default     = "local-vm"
}

variable "platform_namespace" {
  type        = string
  description = "Target namespace for grabber services"
  default     = "robot-platform"
}

variable "monitoring_namespace" {
  type        = string
  description = "Target namespace for prometheus stack"
  default     = "monitoring"
}

variable "ingress_namespace" {
  type        = string
  description = "Target namespace for ingress controller"
  default     = "ingress-nginx"
}

variable "cloudflare_namespace" {
  type        = string
  description = "Target namespace for cloudflared"
  default     = "cloudflare"
}

variable "kubeconfig_path" {
  type        = string
  description = "Absolute path to the kubeconfig authentication file"
  default     = "/home/ubuntu/.kube/config"
}

variable "root_domain" {
  type        = string
  description = "Root domain mapped on Cloudflare"
}

variable "dashboard_domain" {
  type        = string
  description = "Public domain to expose frontend dashboard"
}

variable "api_domain" {
  type        = string
  description = "Public domain to expose api-gateway"
}

variable "grafana_domain" {
  type        = string
  description = "Public domain to expose Grafana console"
}

variable "mqtt_domain" {
  type        = string
  description = "Public domain to expose Mosquitto websocket port"
}

variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare Account ID string"
  default     = ""
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Target DNS Zone ID string"
  default     = ""
}

variable "cloudflare_tunnel_id" {
  type        = string
  description = "Cloudflare Tunnel ID string"
  default     = ""
}

variable "enable_monitoring" {
  type        = bool
  description = "Flag to deploy monitoring helm charts"
  default     = true
}

variable "enable_cloudflare_dns" {
  type        = bool
  description = "Flag to deploy Cloudflare DNS host mapping records"
  default     = true
}

variable "enable_cloudflare_tunnel_resources" {
  type        = bool
  description = "Flag to declare local Cloudflare Tunnel resources within Terraform state"
  default     = false
}

variable "storage_class_name" {
  type        = string
  description = "Cluster StorageClass provider name"
  default     = "local-path"
}

variable "prometheus_storage_size" {
  type        = string
  description = "PVC size for prometheus metrics database"
  default     = "10Gi"
}

variable "grafana_storage_size" {
  type        = string
  description = "PVC size for Grafana storage configurations"
  default     = "2Gi"
}

variable "backup_storage_size" {
  type        = string
  description = "PVC size for mysql dump database backups"
  default     = "10Gi"
}

variable "prometheus_retention" {
  type        = string
  description = "Retention duration parameter for Prometheus server"
  default     = "7d"
}

variable "ingress_nginx_chart_version" {
  type        = string
  description = "Helm chart version for Ingress Nginx"
  default     = "4.10.1"
}

variable "kube_prometheus_stack_version" {
  type        = string
  description = "Helm chart version for Kube Prometheus Stack"
  default     = "60.0.1"
}
