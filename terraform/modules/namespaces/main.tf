resource "kubernetes_namespace" "platform" {
  metadata {
    name = var.platform_namespace
    labels = merge(var.common_labels, {
      name     = var.platform_namespace
      security = "platform-core"
    })
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
    labels = merge(var.common_labels, {
      name = var.monitoring_namespace
    })
  }
}

resource "kubernetes_namespace" "ingress" {
  metadata {
    name = var.ingress_namespace
    labels = merge(var.common_labels, {
      name = var.ingress_namespace
    })
  }
}

resource "kubernetes_namespace" "cloudflare" {
  metadata {
    name = var.cloudflare_namespace
    labels = merge(var.common_labels, {
      name = var.cloudflare_namespace
    })
  }
}
