#!/usr/bin/env bash
# deploy-cloudflare.sh - Deploy Cloudflare Tunnel client daemon (cloudflared)
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=============================================="
echo " Deploying Cloudflare Tunnel (cloudflared)..."
echo "=============================================="

# 1. Validate secret existence
if ! kubectl get secret cloudflare-tunnel-token -n cloudflare &>/dev/null; then
    echo "Error: Secret 'cloudflare-tunnel-token' not found in namespace 'cloudflare'." >&2
    echo "Please configure CLOUDFLARE_TUNNEL_TOKEN in your .env and run 'make secrets' first." >&2
    exit 1
fi

# 2. Apply Cloudflare deployment
echo "Applying cloudflared deployment manifest..."
kubectl apply -f "${REPO_ROOT}/cloudflare/deployment.yaml"

# 3. Wait for deployment rollout
echo "Waiting for cloudflared deployment rollout..."
kubectl rollout status deployment/cloudflared -n cloudflare --timeout=120s

echo "=============================================="
echo " Cloudflare Tunnel deployed successfully!"
echo "=============================================="
