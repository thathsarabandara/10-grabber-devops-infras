#!/usr/bin/env bash
# terraform-apply.sh - Apply the generated Terraform configuration changes
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
echo " Applying Terraform changes: ${TF_ENV}..."
echo "=============================================="

export KUBECONFIG="$KUBECONFIG_PATH"

if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN"
fi

if [[ -f "$PLAN_FILE" ]]; then
    echo "Found compiled tfplan. Executing plan changes..."
    terraform -chdir="$TF_DIR" apply "$PLAN_FILE"
    # Clean up plan after execution
    rm -f "$PLAN_FILE"
else
    echo "No tfplan file found. Running apply with interactive prompt..."
    VARS_ARGS=()
    if [[ -f "${REPO_ROOT}/config/terraform.tfvars" ]]; then
        VARS_ARGS+=("-var-file=${REPO_ROOT}/config/terraform.tfvars")
    elif [[ -f "${TF_DIR}/terraform.tfvars" ]]; then
        VARS_ARGS+=("-var-file=terraform.tfvars")
    fi
    terraform -chdir="$TF_DIR" apply "${VARS_ARGS[@]}"
fi

echo "=============================================="
echo " Terraform apply completed successfully!"
echo " Outputs:"
terraform -chdir="$TF_DIR" output
echo "=============================================="
