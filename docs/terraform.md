# Terraform Infrastructure Management

This document details the configuration layout, modular structure, provider setup, and local state limits of the Terraform files in the `devops-infra` repository.

## Directory Structure

```text
terraform/
├── versions.tf           # Module versions constraints (Kubernetes, Helm, Cloudflare)
├── providers.tf          # Provider setup (authenticates via KUBECONFIG/API token)
├── variables.tf          # Typed variables declarations
├── locals.tf             # Shared labels and composite strings
├── main.tf               # Environment composition composition
├── outputs.tf            # Service names and namespaces outputs
├── backend.tf.example    # Remote state S3 and Terraform Cloud settings
│
├── environments/
│   └── local-vm/         # Target configuration folder for single Ubuntu VM
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── terraform.tfvars.example
│       └── backend.tf.example
│
└── modules/
    ├── namespaces/       # Deploys platform, ingress, monitoring, and cloudflare namespaces
    ├── ingress-nginx/    # Installs ingress controller using Helm (ClusterIP mode)
    ├── monitoring/       # Installs kube-prometheus-stack using Helm
    ├── cloudflare/       # Manages proxied DNS mapping records to the tunnel
    └── storage/          # Registers backup PV/PVC parameters
```

---

## State Management and Backends

### Local State
By default, the `local-vm` environment manages state inside a local `terraform.tfstate` file.
- **Limitation**: Local state is suitable for a single-VM student portfolio or test environment, but it does not support team collaboration, state locking, or disaster recovery.

### Remote Backend Options
To transition to a production configuration:
1. **Amazon S3**: Protects state inside S3 with locking managed by DynamoDB. Copy `backend.tf.example` to `backend.tf` and uncomment the `s3` block.
2. **Terraform Cloud**: Manages remote state and execution. Uncomment the `cloud` block in `backend.tf.example` and set your organization name.

---

## Standard Workflow Commands

All Terraform commands are executed via wrapper scripts inside the `scripts/` directory or Makefile targets:

```bash
# 1. Format code check
make tf-fmt

# 2. Syntax validation
make tf-validate

# 3. Plan changes
make tf-plan

# 4. Apply plan configurations
make tf-apply

# 5. Output values
make tf-output

# 6. Decommission resources
make tf-destroy
```

## Security Credentials Setup

- **Kubernetes and Helm Providers**: Automatically authenticate using the local `$HOME/.kube/config` generated during `make install`.
- **Cloudflare Provider**: Authenticates using the `CLOUDFLARE_API_TOKEN` environment variable. Do not write API tokens in plain-text variable files. Load the token from the secrets configuration before executing plan/apply targets.
