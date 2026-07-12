#!/usr/bin/env bash
# restart-platform.sh - Restart application microservices (and optionally infrastructure)
set -Eeuo pipefail

PLATFORM_NAMESPACE="robot-platform"
RESTART_ALL=false

# Parse command line flags
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "--all" || "$1" == "-a" ]]; then
        RESTART_ALL=true
    else
        echo "Unknown argument: $1" >&2
        echo "Usage: $0 [--all | -a]" >&2
        exit 1
    fi
fi

echo "=============================================="
echo " Restarting platform services..."
echo "=============================================="

# Array of target deployments
APPS=(
    "auth-service"
    "robot-service"
    "telemetry-service"
    "ai-service"
    "api-gateway"
    "frontend"
)

for app in "${APPS[@]}"; do
    echo "Initiating rolling restart for deployment/${app}..."
    kubectl rollout restart deployment/"${app}" -n "$PLATFORM_NAMESPACE"
done

# Wait for application rollouts to finish
for app in "${APPS[@]}"; do
    echo "Waiting for rollout restart of deployment/${app} to complete..."
    kubectl rollout status deployment/"${app}" -n "$PLATFORM_NAMESPACE" --timeout=120s
done

if [[ "$RESTART_ALL" == "true" ]]; then
    echo "----------------------------------------------"
    echo "Restarting databases and messaging services..."
    echo "----------------------------------------------"
    
    echo "Restarting MySQL..."
    kubectl rollout restart statefulset/mysql -n "$PLATFORM_NAMESPACE"
    
    echo "Restarting Redis..."
    kubectl rollout restart statefulset/redis -n "$PLATFORM_NAMESPACE"
    
    echo "Restarting MQTT..."
    kubectl rollout restart deployment/mqtt -n "$PLATFORM_NAMESPACE"
    
    echo "Restarting Grafana..."
    kubectl rollout restart deployment/prometheus-grafana -n monitoring
    
    echo "Restarting Cloudflare Tunnel..."
    kubectl rollout restart deployment/cloudflared -n cloudflare
    
    # Wait for infrastructure components
    kubectl rollout status statefulset/mysql -n "$PLATFORM_NAMESPACE" --timeout=120s
    kubectl rollout status statefulset/redis -n "$PLATFORM_NAMESPACE" --timeout=120s
    kubectl rollout status deployment/mqtt -n "$PLATFORM_NAMESPACE" --timeout=120s
fi

echo "=============================================="
echo " Restart command execution complete!"
echo "=============================================="
