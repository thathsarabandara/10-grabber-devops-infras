#!/usr/bin/env bash
# install-k3s.sh - Install single-node k3s cluster (disabling default Traefik)
set -Eeuo pipefail

echo "=============================================="
echo " Installing k3s (disabling Traefik)..."
echo "=============================================="

# 1. Download and run k3s installation script
# Traefik is disabled because NGINX Ingress Controller is specified
if ! command -v k3s &> /dev/null; then
    curl -sfL https://get.k3s.io | sh -s - --disable traefik
else
    echo "k3s is already installed. Skipping installation command."
fi

# 2. Configure kubeconfig for the current non-root user
USER_HOME="${HOME:-/home/$(logname)}"
USER_UID="$(id -u "$(logname)")"
USER_GID="$(id -g "$(logname)")"

echo "Configuring kubeconfig for user profile at ${USER_HOME}..."
mkdir -p "${USER_HOME}/.kube"
sudo cp /etc/rancher/k3s/k3s.yaml "${USER_HOME}/.kube/config"
sudo chown -R "${USER_UID}:${USER_GID}" "${USER_HOME}/.kube"
chmod 600 "${USER_HOME}/.kube/config"

# Also configure it for the root user running this script
mkdir -p "$HOME/.kube"
sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

export KUBECONFIG="${USER_HOME}/.kube/config"

# 3. Wait for Node readiness
echo "Waiting for k3s node to transition to 'Ready' state..."
TIMEOUT=120
COUNTER=0
until kubectl get nodes | grep -q -E "Ready"; do
    if [ "$COUNTER" -ge "$TIMEOUT" ]; then
        echo "Error: Timeout waiting for k3s node to become ready." >&2
        exit 1
    fi
    sleep 2
    COUNTER=$((COUNTER + 2))
done

echo "=============================================="
echo " k3s Installed and Ready!"
echo " Nodes:"
kubectl get nodes -o wide
echo "=============================================="
