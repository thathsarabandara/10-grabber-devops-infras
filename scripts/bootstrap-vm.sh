#!/usr/bin/env bash
# bootstrap-vm.sh - Prepare Ubuntu VM for Grabber Platform deployment
set -Eeuo pipefail

# Ensure running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run with sudo or as root." >&2
   exit 1
fi

echo "=============================================="
echo " Bootstrapping Ubuntu Server VM..."
echo "=============================================="

# 1. Update and Upgrade System Packages
echo "Updating apt cache and upgrading packages..."
apt-get update -y
apt-get upgrade -y

# 2. Install Essential VM Tools
echo "Installing common system administration tools..."
apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    jq \
    unzip \
    ca-certificates \
    gnupg \
    ufw \
    systemd-timesyncd

# 3. Configure Time Synchronization
echo "Configuring and enabling timesyncd..."
systemctl enable systemd-timesyncd
systemctl start systemd-timesyncd
timedatectl set-ntp true
echo "Time synchronization status:"
timedatectl status

# 4. Configure Firewall (SSH only)
echo "Configuring UFW (Uncomplicated Firewall)..."
# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH only (assuming port 22; adapt if using a custom port)
ufw allow ssh
echo "UFW rules updated. Note: Cloudflare Tunnel operates via outbound connections,"
echo "meaning inbound ports 80/443 do NOT need to be open to the internet."

# Enable firewall without interactive prompt
ufw --force enable
ufw status verbose

echo ""
echo "=============================================="
echo " VM Bootstrapping Completed Successfully."
echo "=============================================="
