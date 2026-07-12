variable "argocd_namespace" {
  type        = string
  description = "Target namespace to deploy Argo CD"
  default     = "argocd"
}

variable "argocd_chart_version" {
  type        = string
  description = "Helm chart version for Argo CD"
  default     = "7.3.11" # Current stable community Helm version
}

variable "common_labels" {
  type        = map(string)
  description = "Common labels to apply to resources"
}
