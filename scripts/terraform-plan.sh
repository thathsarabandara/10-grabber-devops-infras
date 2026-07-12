#!/usr/bin/env bash
# terraform-plan.sh - Validate configurations and output an execution plan
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
PLAN_FILE="${TF_DIR}/tfplan"

echo "=============================================="
echo " Preparing Terraform Plan: ${TF_ENV}..."
echo "=============================================="

# Export authentication parameters
export KUBECONFIG="$KUBECONFIG_PATH"

if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN"
fi

# 1. Format Check
echo "Running style formatting checks..."
terraform -chdir="${REPO_ROOT}/terraform" fmt -check -recursive

# 2. Validation
echo "Validating syntax configurations..."
terraform -chdir="$TF_DIR" validate

# 3. Plan Generation
echo "Generating execution plan output..."
# Check for secrets config to pass variable overrides securely
VARS_ARGS=()
if [[ -f "${REPO_ROOT}/config/terraform.tfvars" ]]; then
    VARS_ARGS+=("-var-file=${REPO_ROOT}/config/terraform.tfvars")
elif [[ -f "${TF_DIR}/terraform.tfvars" ]]; then
    VARS_ARGS+=("-var-file=terraform.tfvars")
fi

terraform -chdir="$TF_DIR" plan "${VARS_ARGS[@]}" -out="$PLAN_FILE"

echo "=============================================="
echo " Plan compiled and outputted to tfplan."
echo "=============================================="
