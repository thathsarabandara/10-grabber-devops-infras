module "namespaces" {
  source = "./modules/namespaces"

  platform_namespace   = var.platform_namespace
  monitoring_namespace = var.monitoring_namespace
  ingress_namespace    = var.ingress_namespace
  cloudflare_namespace = var.cloudflare_namespace
  common_labels        = locals.common_labels
}

module "storage" {
  source = "./modules/storage"

  platform_namespace  = module.namespaces.platform_namespace_name
  storage_class_name  = var.storage_class_name
  backup_storage_size = var.backup_storage_size
  common_labels       = locals.common_labels
}

module "ingress_nginx" {
  source = "./modules/ingress-nginx"

  ingress_namespace           = module.namespaces.ingress_namespace_name
  ingress_nginx_chart_version = var.ingress_nginx_chart_version
  monitoring_namespace        = module.namespaces.monitoring_namespace_name
  common_labels               = locals.common_labels

  depends_on = [module.namespaces]
}

module "monitoring" {
  source = "./modules/monitoring"

  enable_monitoring             = var.enable_monitoring
  monitoring_namespace          = module.namespaces.monitoring_namespace_name
  platform_namespace            = module.namespaces.platform_namespace_name
  kube_prometheus_stack_version = var.kube_prometheus_stack_version
  storage_class_name            = var.storage_class_name
  prometheus_storage_size       = var.prometheus_storage_size
  grafana_storage_size          = var.grafana_storage_size
  prometheus_retention          = var.prometheus_retention
  common_labels                 = locals.common_labels

  depends_on = [
    module.namespaces,
    module.storage
  ]
}

module "cloudflare" {
  source = "./modules/cloudflare"

  enable_cloudflare_dns              = var.enable_cloudflare_dns
  enable_cloudflare_tunnel_resources = var.enable_cloudflare_tunnel_resources
  cloudflare_account_id              = var.cloudflare_account_id
  cloudflare_zone_id                 = var.cloudflare_zone_id
  cloudflare_tunnel_id               = var.cloudflare_tunnel_id
  tunnel_cname_target                = locals.tunnel_cname_target
  
  dashboard_domain = var.dashboard_domain
  api_domain       = var.api_domain
  grafana_domain   = var.grafana_domain
  mqtt_domain      = var.mqtt_domain
}
