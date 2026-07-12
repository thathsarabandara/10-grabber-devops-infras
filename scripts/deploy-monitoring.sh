#!/usr/bin/env bash
# deploy-monitoring.sh - Deploy kube-prometheus-stack and custom dashboards/alerts
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=============================================="
echo " Deploying monitoring stack..."
echo "=============================================="

# 1. Add Prometheus Helm repo and update
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 2. Deploy kube-prometheus-stack
echo "Installing kube-prometheus-stack via Helm..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f "${REPO_ROOT}/helm/monitoring-values.yaml"

# 3. Apply custom PrometheusRule resources (alerting rules)
echo "Applying custom Prometheus alert rules..."
kubectl apply -f "${REPO_ROOT}/monitoring/alert-rules/"

# 4. Apply Grafana Dashboard ConfigMaps for provisioning
echo "Applying provisioning Grafana dashboards..."
kubectl apply -f "${REPO_ROOT}/monitoring/dashboards/"

# 5. Apply any standalone service monitors
echo "Applying ServiceMonitors..."
if ls "${REPO_ROOT}"/monitoring/service-monitors/*.yaml &>/dev/null; then
    kubectl apply -f "${REPO_ROOT}/monitoring/service-monitors/"
fi

# Wait for prometheus-operator deployment to become ready
echo "Waiting for prometheus operator rollout..."
kubectl rollout status deployment/prometheus-operator -n monitoring --timeout=180s

echo "=============================================="
echo " Monitoring stack deployment complete!"
echo "=============================================="
