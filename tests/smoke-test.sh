#!/usr/bin/env bash
# smoke-test.sh - Validate basic platform container state and routes
set -Eeuo pipefail

echo "=============================================="
echo " Starting Platform Smoke Test..."
echo "=============================================="

ERRORS=0

# 1. Verify critical local services exist in robot-platform namespace
SERVICES=(
  "frontend"
  "api-gateway"
  "auth-service"
  "robot-service"
  "telemetry-service"
  "ai-service"
  "mysql"
  "redis"
  "mqtt"
)

echo "Checking Kubernetes service availability..."
for svc in "${SERVICES[@]}"; do
  if kubectl get service "$svc" -n robot-platform &>/dev/null; then
    echo "Service $svc: OK"
  else
    echo "Service $svc: MISSING" >&2
    ERRORS=$((ERRORS + 1))
  fi
done

# 2. Check internal pod readiness status
echo "Checking pods state..."
RUNNING_PODS=$(kubectl get pods -n robot-platform -o jsonpath='{.items[*].status.phase}')
if [[ "$RUNNING_PODS" =~ "Failed" || "$RUNNING_PODS" =~ "Unknown" ]]; then
  echo "Warning: Some pods are in failed/unknown state." >&2
  ERRORS=$((ERRORS + 1))
fi

# 3. Check Ingress resources exist
echo "Checking Ingress mappings..."
INGRESSES=(
  "dashboard-ingress"
  "api-ingress"
  "mqtt-websocket-ingress"
)
for ing in "${INGRESSES[@]}"; do
  if kubectl get ingress "$ing" -n robot-platform &>/dev/null; then
    echo "Ingress $ing: OK"
  else
    echo "Ingress $ing: MISSING" >&2
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ $ERRORS -eq 0 ]]; then
  echo "=============================================="
  echo " SMOKE TEST SUCCESSFUL!"
  echo "=============================================="
  exit 0
else
  echo "=============================================="
  echo " SMOKE TEST FAILED: $ERRORS errors found."
  echo "=============================================="
  exit 1
fi
