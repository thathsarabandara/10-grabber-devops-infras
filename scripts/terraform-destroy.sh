#!/usr/bin/env bash
# terraform-destroy.sh - Decommission Terraform managed infrastructure resources
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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
echo " Starting Terraform Destroy Sequence: ${TF_ENV}..."
echo "=============================================="

# 1. Require explicit confirmation
echo "======================= WARNING ======================="
echo " This action will DELETE all managed resources including:"
echo "   - Helm charts (NGINX ingress, Kube Prometheus Stack)"
echo "   - Isolated system namespaces"
echo "   - Storage Classes and backup allocations"
echo "   - Cloudflare DNS mapping records"
echo "======================================================="
read -r -p "Are you absolutely sure you want to destroy infrastructure? (type 'yes' to confirm): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Destroy operation aborted by user."
    exit 0
fi

export KUBECONFIG="$KUBECONFIG_PATH"

if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN"
fi

VARS_ARGS=()
if [[ -f "${REPO_ROOT}/config/terraform.tfvars" ]]; then
    VARS_ARGS+=("-var-file=${REPO_ROOT}/config/terraform.tfvars")
elif [[ -f "${TF_DIR}/terraform.tfvars" ]]; then
    VARS_ARGS+=("-var-file=terraform.tfvars")
fi

terraform -chdir="$TF_DIR" destroy "${VARS_ARGS[@]}"

echo "=============================================="
echo " Destroy completed."
echo "=============================================="
