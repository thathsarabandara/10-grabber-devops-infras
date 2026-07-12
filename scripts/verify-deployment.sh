#!/usr/bin/env bash
# verify-deployment.sh - Verify cluster health, PVC statuses, and pod readiness
set -Eeuo pipefail

echo "=============================================="
echo " Starting deployment validation..."
echo "=============================================="

ERRORS=0

# Helper to check deployments
check_deployment() {
    local ns=$1
    local name=$2
    echo -n "Checking deployment: ${ns}/${name}... "
    if ! kubectl get deployment "$name" -n "$ns" &>/dev/null; then
        echo "FAIL (does not exist)"
        return 1
    fi
    local ready
    ready=$(kubectl get deployment "$name" -n "$ns" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired
    desired=$(kubectl get deployment "$name" -n "$ns" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    
    if [[ "$ready" == "$desired" ]]; then
        echo "OK (${ready}/${desired} ready)"
        return 0
    else
        echo "FAIL (${ready}/${desired} ready)"
        return 1
    fi
}

# Helper to check statefulsets
check_statefulset() {
    local ns=$1
    local name=$2
    echo -n "Checking statefulset: ${ns}/${name}... "
    if ! kubectl get statefulset "$name" -n "$ns" &>/dev/null; then
        echo "FAIL (does not exist)"
        return 1
    fi
    local ready
    ready=$(kubectl get statefulset "$name" -n "$ns" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired
    desired=$(kubectl get statefulset "$name" -n "$ns" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    
    if [[ "$ready" == "$desired" ]]; then
        echo "OK (${ready}/${desired} ready)"
        return 0
    else
        echo "FAIL (${ready}/${desired} ready)"
        return 1
    fi
}

# 1. Check Node readiness
echo "--- Checking Node Status ---"
if ! kubectl get nodes | grep -q -E "Ready"; then
    echo "Error: No Kubernetes nodes are in 'Ready' state!" >&2
    ERRORS=$((ERRORS + 1))
else
    kubectl get nodes -o wide
fi

# 2. Check PVC health
echo "--- Checking PVC Status ---"
PENDING_PVCS=$(kubectl get pvc -A -o jsonpath='{range .items[?(@.status.phase!="Bound")]}{.metadata.namespace}{"/"}{.metadata.name}{" -> "}{.status.phase}{"\n"}{end}')
if [[ -n "$PENDING_PVCS" ]]; then
    echo "Warning: Unbound/Pending PVCs detected:" >&2
    echo "$PENDING_PVCS" >&2
    ERRORS=$((ERRORS + 1))
else
    echo "All PVCs bound successfully."
    kubectl get pvc -A
fi

# 3. Check Core Infrastructure Rollout
echo "--- Checking Infrastructure Health ---"
check_deployment "ingress-nginx" "ingress-nginx-controller" || ERRORS=$((ERRORS + 1))
check_statefulset "robot-platform" "mysql" || ERRORS=$((ERRORS + 1))
check_statefulset "robot-platform" "redis" || ERRORS=$((ERRORS + 1))
check_deployment "robot-platform" "mqtt" || ERRORS=$((ERRORS + 1))

# 4. Check Applications
echo "--- Checking Microservices Health ---"
check_deployment "robot-platform" "auth-service" || ERRORS=$((ERRORS + 1))
check_deployment "robot-platform" "robot-service" || ERRORS=$((ERRORS + 1))
check_deployment "robot-platform" "telemetry-service" || ERRORS=$((ERRORS + 1))
check_deployment "robot-platform" "ai-service" || ERRORS=$((ERRORS + 1))
check_deployment "robot-platform" "api-gateway" || ERRORS=$((ERRORS + 1))
check_deployment "robot-platform" "frontend" || ERRORS=$((ERRORS + 1))

# 5. Check Cloudflare Tunnel
echo "--- Checking Cloudflare Tunnel Health ---"
check_deployment "cloudflare" "cloudflared" || ERRORS=$((ERRORS + 1))

# 6. Check Monitoring Deployments
echo "--- Checking Monitoring Stack Health ---"
check_deployment "monitoring" "prometheus-operator" || ERRORS=$((ERRORS + 1))
check_deployment "monitoring" "prometheus-grafana" || ERRORS=$((ERRORS + 1))

# 7. Check Ingress resources
echo "--- Ingress endpoints ---"
kubectl get ingress -A

# 8. Pod Status Overview
echo "--- Pod status list (All platform namespaces) ---"
kubectl get pods -n robot-platform
kubectl get pods -n cloudflare
kubectl get pods -n monitoring

if [[ $ERRORS -eq 0 ]]; then
    echo "=============================================="
    echo " SUCCESS: All platform services are healthy!"
    echo "=============================================="
    exit 0
else
    echo "=============================================="
    echo " ERROR: $ERRORS critical components are unhealthy!"
    echo "=============================================="
    exit 1
fi
