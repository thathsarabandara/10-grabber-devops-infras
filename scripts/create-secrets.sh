#!/usr/bin/env bash
# create-secrets.sh - Create Kubernetes secrets from environment variables
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

# 1. Validate environment file existence
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Local .env file not found at ${ENV_FILE}." >&2
    echo "Please copy .env.example to .env and configure all variables first." >&2
    exit 1
fi

# Source environment file (do not print stdout/stderr)
# shellcheck source=/dev/null
source "$ENV_FILE"

# 2. Define namespaces to verify
NAMESPACES=("robot-platform" "monitoring" "cloudflare")

echo "=============================================="
echo " Ensuring Kubernetes namespaces exist..."
echo "=============================================="
for ns in "${NAMESPACES[@]}"; do
    if ! kubectl get namespace "$ns" &>/dev/null; then
        echo "Creating namespace: ${ns}..."
        kubectl create namespace "$ns"
    else
        echo "Namespace already exists: ${ns}"
    fi
done

echo "=============================================="
echo " Creating Kubernetes secrets..."
echo "=============================================="

# Define helper variables with defaults if missing
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root_password_placeholder}"
DB_PASSWORD="${DB_PASSWORD:-db_password_placeholder}"
REDIS_PASSWORD="${REDIS_PASSWORD:-redis_password_placeholder}"
MQTT_USERNAME="${MQTT_USERNAME:-mqtt_user}"
MQTT_PASSWORD="${MQTT_PASSWORD:-mqtt_password_placeholder}"
JWT_SECRET="${JWT_SECRET:-jwt_secret_placeholder_must_be_long_and_secure_value}"
SECRET_KEY="${SECRET_KEY:-secret_key_placeholder}"
GHCR_USERNAME="${GHCR_USERNAME:-ghcr_user}"
GHCR_TOKEN="${GHCR_TOKEN:-ghcr_token_placeholder}"
GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin}"
CLOUDFLARE_TUNNEL_TOKEN="${CLOUDFLARE_TUNNEL_TOKEN:-cloudflare_tunnel_token_placeholder}"

# A. MySQL Secrets
echo "Creating MySQL credentials secret..."
kubectl create secret generic mysql-secrets \
  --namespace=robot-platform \
  --from-literal=mysql-root-password="$MYSQL_ROOT_PASSWORD" \
  --from-literal=mysql-auth-password="$DB_PASSWORD" \
  --from-literal=mysql-robot-password="$DB_PASSWORD" \
  --from-literal=mysql-telemetry-password="$DB_PASSWORD" \
  --from-literal=mysql-ai-password="$DB_PASSWORD" \
  --from-literal=mysql-gateway-password="$DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

# B. Redis Secrets
echo "Creating Redis credentials secret..."
kubectl create secret generic redis-secrets \
  --namespace=robot-platform \
  --from-literal=redis-password="$REDIS_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

# C. MQTT Secrets
echo "Creating MQTT credentials secret..."
kubectl create secret generic mqtt-secrets \
  --namespace=robot-platform \
  --from-literal=mqtt-username="$MQTT_USERNAME" \
  --from-literal=mqtt-password="$MQTT_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

# D. JWT and Secret Key Secrets
echo "Creating JWT security secrets..."
kubectl create secret generic jwt-secrets \
  --namespace=robot-platform \
  --from-literal=jwt-secret="$JWT_SECRET" \
  --from-literal=secret-key="$SECRET_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

# E. GHCR Docker Registry pull secret
echo "Creating GHCR image pull secret..."
kubectl create secret docker-registry ghcr-pull-secret \
  --namespace=robot-platform \
  --docker-server=ghcr.io \
  --docker-username="$GHCR_USERNAME" \
  --docker-password="$GHCR_TOKEN" \
  --docker-email="ops@grabber-platform.local" \
  --dry-run=client -o yaml | kubectl apply -f -

# F. Grafana Admin Password
echo "Creating Grafana admin secret..."
kubectl create secret generic grafana-admin-secret \
  --namespace=monitoring \
  --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

# G. Cloudflare Tunnel Token
echo "Creating Cloudflare Tunnel secret..."
kubectl create secret generic cloudflare-tunnel-token \
  --namespace=cloudflare \
  --from-literal=tunnel-token="$CLOUDFLARE_TUNNEL_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "=============================================="
echo " Secrets created successfully."
echo "=============================================="
