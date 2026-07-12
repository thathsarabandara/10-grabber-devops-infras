.PHONY: install clone update secrets tf-init tf-fmt tf-validate tf-plan tf-apply tf-output tf-destroy infra apps monitoring cloudflare deploy verify status logs restart backup restore uninstall help

# Default target
all: help

help:
	@echo "Grabber Platform DevOps Command Interface"
	@echo "Available commands:"
	@echo "  make install       - Bootstrap VM, install CLI tools, and install k3s"
	@echo "  make clone         - Clone all application repositories"
	@echo "  make update        - Pull and fast-forward all application repositories"
	@echo "  make secrets       - Create Kubernetes secrets from environment variables"
	@echo ""
	@echo "Terraform Operations:"
	@echo "  make tf-init       - Initialize Terraform workspace and download providers"
	@echo "  make tf-fmt        - Check formatting of all Terraform files"
	@echo "  make tf-validate   - Validate Terraform configuration syntax"
	@echo "  make tf-plan       - Generate and show an execution plan"
	@echo "  make tf-apply      - Build or update cloud resources"
	@echo "  make tf-output     - Display Terraform outputs"
	@echo "  make tf-destroy    - Destroy all Terraform-managed resources"
	@echo ""
	@echo "Deployment Operations:"
	@echo "  make infra         - Deploy core datastores (MySQL, Redis, MQTT)"
	@echo "  make apps          - Deploy microservices and frontends"
	@echo "  make monitoring    - Apply alerting rules, dashboards, and ServiceMonitors"
	@echo "  make cloudflare    - Start the Cloudflare Tunnel daemon"
	@echo "  make deploy        - Run full deployment sequence"
	@echo "  make verify        - Run verification tests to validate rollout health"
	@echo "  make status        - Display node, pod, and service status overview"
	@echo "  make logs          - Stream logs from pods (requires SERVICE=<name>)"
	@echo "  make restart       - Restart application microservice deployments"
	@echo "  make backup        - Perform MySQL database backup"
	@echo "  make restore       - Restore database from file (requires BACKUP_FILE=<path>)"
	@echo "  make uninstall     - Uninstall the platform (use MODE=delete-data to wipe volumes)"

install:
	@chmod +x scripts/*.sh
	./scripts/bootstrap-vm.sh
	./scripts/install-tools.sh
	./scripts/install-terraform.sh
	./scripts/install-k3s.sh

clone:
	@chmod +x scripts/*.sh
	./scripts/clone-all-repos.sh

update:
	@chmod +x scripts/*.sh
	./scripts/pull-all-repos.sh

secrets:
	@chmod +x scripts/*.sh
	./scripts/create-secrets.sh

tf-init:
	@chmod +x scripts/*.sh
	./scripts/terraform-init.sh

tf-fmt:
	@chmod +x scripts/*.sh
	terraform -chdir=terraform fmt -check -recursive

tf-validate:
	@chmod +x scripts/*.sh
	./scripts/terraform-plan.sh # Runs validates internally

tf-plan:
	@chmod +x scripts/*.sh
	./scripts/terraform-plan.sh

tf-apply:
	@chmod +x scripts/*.sh
	./scripts/terraform-apply.sh

tf-output:
	@chmod +x scripts/*.sh
	@ENV_FILE=".env"; \
	TF_ENV="local-vm"; \
	if [ -f "$$ENV_FILE" ]; then \
		. ./$$ENV_FILE; \
		TF_ENV=$${TERRAFORM_ENVIRONMENT:-local-vm}; \
	fi; \
	terraform -chdir=terraform/environments/$$TF_ENV output

tf-destroy:
	@chmod +x scripts/*.sh
	./scripts/terraform-destroy.sh

infra:
	@chmod +x scripts/*.sh
	./scripts/deploy-infrastructure.sh

apps:
	@chmod +x scripts/*.sh
	./scripts/deploy-applications.sh

monitoring:
	@chmod +x scripts/*.sh
	./scripts/deploy-monitoring.sh

cloudflare:
	@chmod +x scripts/*.sh
	./scripts/deploy-cloudflare.sh

deploy:
	@chmod +x scripts/*.sh
	./scripts/deploy-infrastructure.sh
	./scripts/deploy-applications.sh
	./scripts/deploy-monitoring.sh
	./scripts/deploy-cloudflare.sh

verify:
	@chmod +x scripts/*.sh
	./scripts/verify-deployment.sh
	./tests/smoke-test.sh
	./tests/api-health-test.sh

status:
	@chmod +x scripts/*.sh
	./scripts/status.sh

logs:
	@chmod +x scripts/*.sh
	@if [ -z "$(SERVICE)" ]; then \
		echo "Usage: make logs SERVICE=<service-name>"; \
		exit 1; \
	fi
	./scripts/logs.sh $(SERVICE)

restart:
	@chmod +x scripts/*.sh
	./scripts/restart-platform.sh

backup:
	@chmod +x scripts/*.sh
	./scripts/backup-mysql.sh

restore:
	@chmod +x scripts/*.sh
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Usage: make restore BACKUP_FILE=/path/to/backup.sql"; \
		exit 1; \
	fi
	./scripts/restore-mysql.sh "$(BACKUP_FILE)"

uninstall:
	@chmod +x scripts/*.sh
	@if [ "$(MODE)" = "delete-data" ]; then \
		./scripts/uninstall-platform.sh --delete-data; \
	else \
		./scripts/uninstall-platform.sh --keep-data; \
	fi
