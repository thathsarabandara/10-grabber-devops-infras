# Cloudflare Tunnel Configuration

This document explains how to set up, secure, and route public hostnames using Cloudflare Tunnel.

## Setup Overview

We split responsibilities between Terraform and Kubernetes:

1. **Terraform**: Manages public DNS records (CNAME) pointing to your tunnel target domain.
2. **Kubernetes**: Runs the `cloudflared` client pod using the tunnel token from your Kubernetes secret.

```text
Public client request -> Cloudflare DNS -> Cloudflare Tunnel Connection -> cloudflared Pod -> NGINX Ingress -> Backend
```

---

## Configuration Steps

### 1. Retrieve Tunnel Token
1. Go to the **Cloudflare Zero Trust Dashboard** (one.dash.cloudflare.com).
2. Go to **Networks** -> **Tunnels** and click **Create a Tunnel**.
3. Name your tunnel (e.g., `grabber-platform-tunnel`) and click **Save**.
4. In the installation instructions, copy the long base64 **Tunnel Token**.
5. Add this token to the `CLOUDFLARE_TUNNEL_TOKEN` variable in your `config/secrets.env` file.

### 2. Configure Terraform DNS settings
Uncomment and configure the Cloudflare variables inside `terraform/environments/local-vm/terraform.tfvars`:
```hcl
cloudflare_account_id = "your_account_id"
cloudflare_zone_id    = "your_zone_id"
cloudflare_tunnel_id  = "your_tunnel_id"
```
Ensure you export your API token before running plan or apply commands:
```bash
export CLOUDFLARE_API_TOKEN="your_cloudflare_api_token"
```

### 3. Route Hostnames
Public hostnames are mapped internally to NGINX Ingress. The mappings are configured in [cloudflare/configmap.yaml](file:///home/thathsara/Desktop/Thathsara/Project/Grabber/11-grabber-devops-infras/cloudflare/configmap.yaml):
- `dashboard.example.com` -> NGINX controller Service (port 80)
- `api.example.com` -> NGINX controller Service (port 80)
- `grafana.example.com` -> NGINX controller Service (port 80)
- `mqtt.example.com` -> NGINX controller Service (port 80)

---

## Edge Protection (Cloudflare Access)

To secure administrative dashboards:
1. Navigate to **Access** -> **Applications** in the Zero Trust dashboard.
2. Click **Add an Application** and select **Self-Hosted**.
3. Set the domain name to `grafana.example.com`.
4. Configure an authentication policy (e.g., email OTP or Google OAuth) to restrict access to authorized team members only.

---

## Troubleshooting Cloudflare 502 Errors

If your public hostnames return a **502 Bad Gateway** error, it means `cloudflared` is running but cannot connect to the internal NGINX Ingress controller:
1. Check the tunnel logs:
   ```bash
   make logs SERVICE=cloudflared
   ```
2. Verify that the NGINX Ingress controller pod is running:
   ```bash
   kubectl get pods -n ingress-nginx
   ```
3. Check the internal routing endpoint specified in the configmap:
   ```bash
   # Should resolve to the internal NGINX controller ClusterIP service
   nslookup ingress-nginx-controller.ingress-nginx.svc.cluster.local
   ```
