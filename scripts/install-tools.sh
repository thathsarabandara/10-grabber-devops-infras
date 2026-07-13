#!/usr/bin/env bash
# install-tools.sh - Install essential CLI tools (kubectl, Helm, jq)
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run with sudo or as root." >&2
   exit 1
fi

echo "=============================================="
echo " Installing CLI and Kubernetes Tools..."
echo "=============================================="

# Ensure apt-transport-https is present
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg jq unzip wget git

# Create keyrings directory if missing
mkdir -p -m 755 /etc/apt/keyrings

# 1. Install kubectl (using v1.30 stable branch)
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
    apt-get update -y
    apt-get install -y kubectl
    echo "kubectl version: $(kubectl version --client --output=yaml | grep gitVersion | head -n 1)"
else
    echo "kubectl is already installed: $(kubectl version --client --output=yaml | grep gitVersion | head -n 1)"
fi

# 2. Install Helm
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
    echo "Helm version: $(helm version --short)"
else
    echo "Helm is already installed: $(helm version --short)"
fi

echo ""
echo "=============================================="
echo " CLI Tools Installation Completed."
echo "=============================================="
