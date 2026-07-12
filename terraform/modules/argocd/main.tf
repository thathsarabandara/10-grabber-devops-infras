resource "kubernetes_namespace" "argocd" {
  metadata {
    name   = var.argocd_namespace
    labels = var.common_labels
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  wait       = false

  # Non-HA settings to reduce resource footprint on a local VM
  set {
    name  = "global.highAvailability.enabled"
    value = "false"
  }

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Disable HTTPS internally so NGINX ingress can terminate SSL easily
  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }

  depends_on = [kubernetes_namespace.argocd]
}
