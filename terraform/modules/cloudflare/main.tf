# DNS Record Mappings to the local tunnel target endpoint
resource "cloudflare_record" "dashboard" {
  count   = var.enable_cloudflare_dns ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = split(".", var.dashboard_domain)[0]
  content = var.tunnel_cname_target
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "api" {
  count   = var.enable_cloudflare_dns ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = split(".", var.api_domain)[0]
  content = var.tunnel_cname_target
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "grafana" {
  count   = var.enable_cloudflare_dns ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = split(".", var.grafana_domain)[0]
  content = var.tunnel_cname_target
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "mqtt" {
  count   = var.enable_cloudflare_dns ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = split(".", var.mqtt_domain)[0]
  content = var.tunnel_cname_target
  type    = "CNAME"
  proxied = true
}
