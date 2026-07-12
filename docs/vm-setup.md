# Ubuntu Server VM Setup Guide

This document describes the sizing, networking, and firewall configurations required to deploy the Grabber DevOps infrastructure on a single Ubuntu Server VM.

## Recommended VM Sizing

Due to running a Kubernetes cluster, a message broker, three database instances (MySQL, Redis, and Mosquitto), six microservice workloads, and a monitoring stack, the host VM should meet the following specifications:

- **CPU Cores**: 4 to 8 vCPUs (Recommended: 6 Cores)
- **Memory (RAM)**: 12 GB to 16 GB (Recommended: 16 GB)
- **Disk Allocation**: 80 GB SSD (NVMe preferred)
- **OS Platform**: Ubuntu Server 22.04 LTS or 24.04 LTS

---

## Operating System Setup

### 1. Network Settings and Static IP
It is highly recommended to configure a static IP on your VM inside your local network. On Ubuntu Server, this is configured via Netplan.

Example configuration (`/etc/netplan/00-installer-config.yaml`):
```yaml
network:
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.150/24
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
      routes:
        - to: default
          via: 192.168.1.1
  version: 2
```
Apply the netplan:
```bash
sudo netplan apply
```

### 2. Time Synchronization (NTP)
Accurate time synchronization is critical for certificates and metrics collection.
Enable and verify `timesyncd`:
```bash
sudo systemctl enable --now systemd-timesyncd
sudo timedatectl set-ntp true
timedatectl status
```

### 3. Firewall (UFW) Configuration
Because all external traffic routes through the outbound Cloudflare Tunnel client, **you do not need to open public inbound ports (80 or 443) on your router or VM firewall**.

Configure UFW to block all inbound traffic except local SSH connections:
```bash
# Block inbound by default
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow local SSH connection
sudo ufw allow 22/tcp comment 'SSH Port'

# Enable UFW
sudo ufw --force enable
sudo ufw status verbose
```
This blocks all direct public scanning from hitting the VM while allowing secure DNS tunnel forwarding.
