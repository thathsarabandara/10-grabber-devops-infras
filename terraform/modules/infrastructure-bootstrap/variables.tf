variable "platform_namespace" {
  type        = string
  description = "Target deployment namespace"
}

variable "platform_name" {
  type        = string
  description = "Name of the platform"
}

variable "common_labels" {
  type        = map(string)
  description = "Common labels to apply to resources"
}
