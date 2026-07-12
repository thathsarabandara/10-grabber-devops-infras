variable "ingress_namespace" {
  type        = string
  description = "Target namespace to install NGINX Ingress"
}

variable "ingress_nginx_chart_version" {
  type        = string
  description = "Helm chart version constraint"
  default     = "4.10.1"
}

variable "monitoring_namespace" {
  type        = string
  description = "Namespace where Prometheus stack is located"
}

variable "common_labels" {
  type        = map(string)
  description = "Common labels to merge with custom ones"
}
