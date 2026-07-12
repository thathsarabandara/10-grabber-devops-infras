variable "enable_cloudflare_dns" {
  type        = bool
  description = "Flag to deploy DNS records on Cloudflare"
  default     = true
}

variable "enable_cloudflare_tunnel_resources" {
  type        = bool
  description = "Flag to manage cloudflare tunnel resources in Terraform"
  default     = false
}

variable "cloudflare_account_id" {
  type        = string
  description = "Target Cloudflare account ID"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Target Cloudflare zone DNS ID"
}

variable "cloudflare_tunnel_id" {
  type        = string
  description = "Target Cloudflare tunnel ID"
}

variable "tunnel_cname_target" {
  type        = string
  description = "Target cfargotunnel domain location"
}

variable "dashboard_domain" {
  type        = string
  description = "Public web UI entry point"
}

variable "api_domain" {
  type        = string
  description = "Public API Gateway entry point"
}

variable "grafana_domain" {
  type        = string
  description = "Public Grafana entry point"
}

variable "mqtt_domain" {
  type        = string
  description = "Public MQTT Websocket entry point"
}
