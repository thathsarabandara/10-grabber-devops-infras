#!/usr/bin/env bash
# terraform-init.sh - Initialize Terraform workspace environment
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source config if exists to find environment target
ENV_FILE="${REPO_ROOT}/.env"
TF_ENV="local-vm"
KUBECONFIG_PATH="$HOME/.kube/config"

if [[ -f "$ENV_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    TF_ENV="${TERRAFORM_ENVIRONMENT:-local-vm}"
    KUBECONFIG_PATH="${KUBECONFIG_PATH:-$HOME/.kube/config}"
fi

TF_DIR="${REPO_ROOT}/terraform/environments/${TF_ENV}"

echo "=============================================="
echo " Initializing Terraform environment: ${TF_ENV}..."
echo "=============================================="

if [[ ! -d "$TF_DIR" ]]; then
    echo "Error: Terraform environment directory ${TF_DIR} does not exist!" >&2
    exit 1
fi

if [[ ! -f "$KUBECONFIG_PATH" ]]; then
    echo "Error: Kubeconfig not found at ${KUBECONFIG_PATH}." >&2
    exit 1
fi

# Export KUBECONFIG for providers
export KUBECONFIG="$KUBECONFIG_PATH"

terraform -chdir="$TF_DIR" init

echo "=============================================="
echo " Terraform workspace initialized."
echo "=============================================="
