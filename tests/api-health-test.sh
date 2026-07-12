#!/usr/bin/env bash
# api-health-test.sh - Call health and ready endpoints to check API gateway responsiveness
set -Eeuo pipefail

echo "=============================================="
echo " Running API Gateway Health Validation..."
echo "=============================================="

# Try calling the local ClusterIP service from a temporary pod if public domains aren't fully resolved yet
echo "Launching temporary test container to query internal API..."
if kubectl run curl-test-pod --rm -i --restart=Never \
  --namespace=robot-platform \
  --image=curlimages/curl:8.8.0 -- \
  curl -s -o /dev/null -w "%{http_code}" http://api-gateway:8000/health | grep -q "200"; then
  echo "Internal API Gateway health endpoint query: SUCCESS (HTTP 200)"
else
  echo "Error: Internal API Gateway health endpoint query failed." >&2
  exit 1
fi

if kubectl run curl-test-pod --rm -i --restart=Never \
  --namespace=robot-platform \
  --image=curlimages/curl:8.8.0 -- \
  curl -s -o /dev/null -w "%{http_code}" http://api-gateway:8000/ready | grep -q "200"; then
  echo "Internal API Gateway readiness endpoint query: SUCCESS (HTTP 200)"
else
  echo "Error: Internal API Gateway readiness endpoint query failed." >&2
  exit 1
fi

echo "=============================================="
echo " API HEALTH CHECKS COMPLETE."
echo "=============================================="
exit 0
