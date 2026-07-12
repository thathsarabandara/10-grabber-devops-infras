locals {
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "grabber-platform"
    "environment"                  = var.environment
  }

  namespaces = {
    platform   = var.platform_namespace
    monitoring = var.monitoring_namespace
    ingress    = var.ingress_namespace
    cloudflare = var.cloudflare_namespace
  }

  tunnel_cname_target = "${var.cloudflare_tunnel_id}.cfargotunnel.com"

  # NGINX internal Ingress service origin endpoint
  ingress_internal_origin = "http://ingress-nginx-controller.${var.ingress_namespace}.svc.cluster.local:80"
}
