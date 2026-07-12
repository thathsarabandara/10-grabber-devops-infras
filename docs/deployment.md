# Deployment Guide

This guide describes how to bootstrap, configure, and deploy the entire Grabber Platform to your local Ubuntu VM.

## Initial Setup and Configuration

Copy the template configuration files to initialize the environment:

```bash
# 1. Copy configurations templates
cp .env.example .env
cp config/repositories.env.example config/repositories.env
cp config/platform.env.example config/platform.env
cp config/domains.env.example config/domains.env
cp config/secrets.env.example config/secrets.env
cp config/terraform.tfvars.example terraform/environments/local-vm/terraform.tfvars
```

---

## Configuration Variables Guide

1. **`.env`**: Defines global parameters like the active Terraform environment and paths to kubeconfig.
2. **`config/repositories.env`**: Mapped coordinates for application source git repos.
3. **`config/platform.env`**: Version tags and replica requirements for microservices.
4. **`config/domains.env`**: Custom dashboard, API, and Grafana domains routing targets.
5. **`config/secrets.env`**: Secure credential bindings (MySQL, Redis, MQTT, JWT, and Cloudflare tokens).
6. **`terraform/environments/local-vm/terraform.tfvars`**: Configuration inputs for Terraform variables.

---

## Deployment Sequence

Deploy the stack in order:

```bash
# 1. Install CLI tools (kubectl, Helm, Terraform) and k3s
sudo make install

# 2. Clone application source files into /opt/grabber-platform/
make clone

# 3. Create Kubernetes secret resources from config/secrets.env
make secrets

# 4. Initialize Terraform providers and backend
make tf-init

# 5. Compile plan and check resource definitions
make tf-plan

# 6. Apply configurations to spin up namespaces, storage, and Helm charts
make tf-apply

# 7. Roll out datastores and MQTT broker
make infra

# 8. Roll out microservices, frontends, and ingress rules
make apps

# 9. Configure alert rules and dashboards
make monitoring

# 10. Start the Cloudflare Tunnel daemon
make cloudflare

# 11. Run verification checks
make verify
```

---

## Required Environment Variables for Commands

The following commands require active secrets:
- `make secrets`: Requires `config/secrets.env` variables to build secrets.
- `make tf-plan` / `make tf-apply`: Requires `CLOUDFLARE_API_TOKEN` set in your terminal environment if Cloudflare DNS records are being deployed.
