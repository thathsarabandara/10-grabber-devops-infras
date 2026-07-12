#!/usr/bin/env bash
# install-terraform.sh - Install Terraform using official HashiCorp APT Repository
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run with sudo or as root." >&2
   exit 1
fi

echo "=============================================="
echo " Installing Terraform..."
echo "=============================================="

if command -v terraform &>/dev/null; then
    echo "Terraform is already installed: $(terraform version -json | jq -r '.terraform_version')"
    exit 0
fi

# Add HashiCorp GPG Key
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp Repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

apt-get update -y
apt-get install -y terraform

echo "Terraform version: $(terraform version -json | jq -r '.terraform_version')"
echo "=============================================="
