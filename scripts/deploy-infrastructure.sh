#!/usr/bin/env bash
# deploy-infrastructure.sh - Deploy namespaces, ingress, storage, databases, and message brokers
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=============================================="
echo " Starting core infrastructure deployment..."
echo "=============================================="

# 1. Namespaces
echo "Deploying namespaces..."
kubectl apply -f "${REPO_ROOT}/kubernetes/namespaces/"

# 2. NGINX Ingress Controller
echo "Deploying NGINX Ingress Controller via Helm..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  -f "${REPO_ROOT}/helm/ingress-nginx-values.yaml"

echo "Waiting for NGINX Ingress Controller pods to become Ready..."
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=180s

# 3. Storage
echo "Applying storage configurations..."
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/storage/local-path-storage.yaml"

# 4. MySQL
echo "Deploying MySQL Database..."
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/mysql/init-configmap.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/mysql/configmap.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/mysql/service.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/mysql/statefulset.yaml"

echo "Waiting for MySQL StatefulSet rollout to complete..."
kubectl rollout status statefulset/mysql -n robot-platform --timeout=180s

# 5. Redis
echo "Deploying Redis Cache..."
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/redis/configmap.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/redis/service.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/redis/statefulset.yaml"

echo "Waiting for Redis StatefulSet rollout to complete..."
kubectl rollout status statefulset/redis -n robot-platform --timeout=180s

# 6. MQTT Broker
echo "Deploying Mosquitto MQTT Broker..."
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/mqtt/persistent-volume-claim.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/mqtt/configmap.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/mqtt/service.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/mqtt/deployment.yaml"

echo "Waiting for MQTT deployment rollout to complete..."
kubectl rollout status deployment/mqtt -n robot-platform --timeout=180s

echo "=============================================="
echo " Infrastructure deployment complete!"
echo "=============================================="
