resource "helm_release" "prometheus" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version
  namespace  = var.monitoring_namespace
  wait       = true
  timeout    = 600

  # Overlay configurations for a single-VM k3s environment
  set {
    name  = "prometheusOperator.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "prometheusOperator.resources.requests.memory"
    value = "64Mi"
  }

  set {
    name  = "prometheusOperator.resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "prometheusOperator.resources.limits.memory"
    value = "128Mi"
  }

  # Alertmanager settings
  set {
    name  = "alertmanager.alertmanagerSpec.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.resources.requests.memory"
    value = "64Mi"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.resources.limits.memory"
    value = "128Mi"
  }

  # Prometheus Server spec configurations
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.cpu"
    value = "1000m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = "1500Mi"
  }

  # Enable cluster-wide discovery for ServiceMonitors and PodMonitors
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  # Grafana Spec Configurations
  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = var.storage_class_name
  }

  set {
    name  = "grafana.persistence.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "grafana.persistence.size"
    value = var.grafana_storage_size
  }

  set {
    name  = "grafana.admin.existingSecret"
    value = "grafana-admin-secret"
  }

  set {
    name  = "grafana.admin.adminPasswordKey"
    value = "admin-password"
  }

  set {
    name  = "grafana.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "grafana.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "grafana.resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "grafana.resources.limits.memory"
    value = "512Mi"
  }
}
