#!/usr/bin/env bash
# uninstall-platform.sh - Uninstall applications and optional infrastructure data
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MODE="keep-data"

# Parse arguments
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "--delete-data" ]]; then
        MODE="delete-data"
    elif [[ "$1" == "--keep-data" ]]; then
        MODE="keep-data"
    else
        echo "Unknown argument: $1" >&2
        echo "Usage: $0 [--keep-data | --delete-data]" >&2
        exit 1
    fi
fi

echo "=============================================="
echo " Starting Platform Uninstallation (Mode: ${MODE})..."
echo "=============================================="

# Define application deployments to uninstall
APPS=(
    "frontend"
    "api-gateway"
    "auth-service"
    "robot-service"
    "telemetry-service"
    "ai-service"
)

uninstall_apps_only() {
    echo "Uninstalling microservices deployments..."
    for app in "${APPS[@]}"; do
        if kubectl get deployment "$app" -n robot-platform &>/dev/null; then
            echo "Deleting deployment/${app}..."
            kubectl delete deployment "$app" -n robot-platform --ignore-not-found
            kubectl delete service "$app" -n robot-platform --ignore-not-found
            kubectl delete configmap "$app" -n robot-platform --ignore-not-found
        fi
    done
    
    echo "Deleting Ingress resources..."
    kubectl delete -f "${REPO_ROOT}/kubernetes/ingress/" --ignore-not-found
    
    echo "Deleting NetworkPolicies..."
    kubectl delete -f "${REPO_ROOT}/kubernetes/security/" --ignore-not-found
    
    echo "Deleting Cloudflare Tunnel deployment..."
    kubectl delete deployment/cloudflared -n cloudflare --ignore-not-found
}

delete_all_resources() {
    echo "Uninstalling microservices and deleting all configurations..."
    uninstall_apps_only
    
    echo "Uninstalling infrastructure components (MySQL, Redis, MQTT)..."
    kubectl delete statefulset mysql -n robot-platform --ignore-not-found
    kubectl delete service mysql -n robot-platform --ignore-not-found
    kubectl delete configmap mysql-config mysql-init-script -n robot-platform --ignore-not-found
    
    kubectl delete statefulset redis -n robot-platform --ignore-not-found
    kubectl delete service redis -n robot-platform --ignore-not-found
    kubectl delete configmap redis-config -n robot-platform --ignore-not-found
    
    kubectl delete deployment mqtt -n robot-platform --ignore-not-found
    kubectl delete service mqtt -n robot-platform --ignore-not-found
    kubectl delete configmap mqtt-config -n robot-platform --ignore-not-found
    kubectl delete pvc mqtt-data-pvc -n robot-platform --ignore-not-found
    
    # Delete PVs/PVCs associated with statefulsets (MySQL/Redis)
    kubectl delete pvc -l app=mysql -n robot-platform --ignore-not-found
    kubectl delete pvc -l app=redis -n robot-platform --ignore-not-found

    echo "Uninstalling Helm charts..."
    helm uninstall ingress-nginx -n ingress-nginx || true
    helm uninstall prometheus -n monitoring || true
    
    echo "Deleting secrets..."
    kubectl delete secret mysql-secrets redis-secrets mqtt-secrets jwt-secrets ghcr-pull-secret -n robot-platform --ignore-not-found
    kubectl delete secret cloudflare-tunnel-token -n cloudflare --ignore-not-found
    kubectl delete secret grafana-admin-secret -n monitoring --ignore-not-found
    
    echo "Deleting namespaces..."
    kubectl delete namespace robot-platform monitoring ingress-nginx cloudflare --ignore-not-found
}

if [[ "$MODE" == "delete-data" ]]; then
    echo "======================= WARNING ======================="
    echo " This action will DELETE all namespaces, configurations,"
    echo " HELM deployments, and ALL PERSISTENT DATABASES / PVs!"
    echo "======================================================="
    read -r -p "Are you absolutely sure you want to wipe everything? (type 'yes' to confirm): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo "Aborting uninstallation."
        exit 0
    fi
    delete_all_resources
else
    # Keep data mode (default)
    uninstall_apps_only
    echo "Platform apps uninstalled. Database statefulsets, PVCs, and namespaces preserved."
fi

echo "=============================================="
echo " Uninstallation completed."
echo "=============================================="
