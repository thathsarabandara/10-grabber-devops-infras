variable "platform_namespace" {
  type        = string
  description = "Namespace for platform workloads"
}

variable "monitoring_namespace" {
  type        = string
  description = "Namespace for monitoring tools"
}

variable "ingress_namespace" {
  type        = string
  description = "Namespace for NGINX ingress resources"
}

variable "cloudflare_namespace" {
  type        = string
  description = "Namespace for Cloudflare Tunnel connector daemon"
}

variable "common_labels" {
  type        = map(string)
  description = "Common labels to apply to resources"
}
