# ⚙️ Grabber DevOps & Infrastructure

> **Repository `11`** · Operations, deployment automation, and monitoring hub for the Grabber ecosystem. Manages Docker Compose orchestrations, automated database initialization scripts, Prometheus/Grafana provisioning configurations, and Kubernetes Infrastructure-as-Code (IaC) deployment manifests using Terraform.

[![Ops](https://img.shields.io/badge/Ops-Docker%20Compose-2496ED?logo=docker&style=flat-square)]()
[![IaC](https://img.shields.io/badge/IaC-Terraform%20%7C%20Kubernetes-7B42BC?logo=terraform&style=flat-square)]()
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%7C%20Grafana-orange?logo=grafana&style=flat-square)]()
[![Status](https://img.shields.io/badge/Status-Active-brightgreen.svg?style=flat-square)]()

---

## 🎥 Video Demonstration

<div align="center">
  <a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">
    <img src="https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg" alt="Grabber Demo Video" width="70%">
  </a>
  <br/>
  <sub>Click the image above to watch the demonstration video on YouTube.</sub>
</div>

---

## 🧭 What Is This Repository?

The **DevOps and Infrastructure repository** orchestrates the deployment and scaling of the Grabber system. It separates the runtime application logic from system deployment, networking, and monitoring.

### Key Core Functions
1. **Master Environment Configuration**: Consolidates all environment credentials (`.env`) for databases, brokers, emails, and API configurations.
2. **Docker Compose Orchestrator**: Runs the complete local development stack, including databases, admin tools, MQTT brokers, microservices, and monitoring dashboards.
3. **Database Auto-Initialization**: Provisions and configures MySQL schemas and user permissions on startup.
4. **Scraping & Monitoring**: Configures Prometheus to collect API Gateway metrics and Grafana to visualize system performance.
5. **Infrastructure-as-Code (IaC)**: Includes Terraform manifests to deploy databases, caches, gateways, and monitoring stacks to Kubernetes namespaces.

---

## 📦 Project Structure

```
11-grabber-devops-infras/
├── databases/
│   └── mysql-init.sql      # Database provisioning script (MySQL initialization)
├── grafana/
│   └── provisioning/
│       ├── dashboards/     # Automated Grafana dashboard imports
│       └── datasources/    # Default Prometheus datasource integrations
├── prometheus/
│   └── prometheus.yml      # Scraping configurations for API Gateway metrics
├── terraform/
│   └── k8s/                # Kubernetes IaC configurations using Terraform
│       ├── provider.tf      # Kubernetes resource provider
│       ├── namespaces.tf    # System & monitoring namespace declarations
│       ├── secrets.tf       # DB/JWT credential variables
│       ├── mysql.tf         # Persistent MySQL DB deployment
│       ├── redis.tf         # Ephemeral Redis cache deployment
│       ├── api_gateway.tf   # Node.js API Gateway deployment
│       ├── auth_service.tf  # FastAPI Auth service deployment
│       └── monitoring.tf    # Prometheus/Grafana monitoring deployment
├── .env                    # System-wide configuration environment variables
├── docker-compose.yml      # Master local dev composer orchestration file
└── README.md
```

### Module Code Index

* **Docker Orchestrator**:
  * [docker-compose.yml](docker-compose.yml): Coordinates the launch sequence of the entire backend stack, establishing container dependency hierarchies (e.g., microservices waiting for database healthchecks).

* **Database Provisioner**:
  * [databases/mysql-init.sql](databases/mysql-init.sql): Runs automatically when the MySQL container starts. Creates the 5 isolated schemas (`grabber_gateway`, `grabber_auth`, `grabber_robot`, `grabber_telemetry`, and `grabber_ai`) and configures user permissions.

* **Metrics & Dashboards**:
  * [prometheus/prometheus.yml](prometheus/prometheus.yml): Configures Prometheus to scrape gateway metrics from `api-gateway:8000` at a 15-second interval.
  * [grafana/provisioning/datasources/datasource.yml](grafana/provisioning/datasources/datasource.yml): Configures the default Prometheus datasource at `http://prometheus:9090`.
  * [grafana/provisioning/dashboards/dashboard.yml](grafana/provisioning/dashboards/dashboard.yml): Automatically mounts dashboard JSON templates (such as the [API Gateway Dashboard](grafana/provisioning/dashboards/api-gateway.json)) to Grafana.

* **Infrastructure-as-Code (IaC)**:
  * [terraform/k8s/namespaces.tf](terraform/k8s/namespaces.tf): Defines the target namespaces for Kubernetes deployments (`grabber-system` and `monitoring`).
  * [terraform/k8s/variables.tf](terraform/k8s/variables.tf): Declares configurable inputs for namespaces, database passwords, and JWT secret keys.

---

## ⚡ Master Environment Variables Checklist

The system-wide [.env](.env) file configures the following key settings:

### 1. Database Credentials
* `DB_HOST`: Host address of the database server (`db`).
* `DB_USER` / `DB_PASSWORD`: Credentials for the microservice database user.
* `MYSQL_ROOT_PASSWORD`: Master administrator password for the MySQL server.
* `DB_NAME_*`: Database names for the gateway, auth, robot, telemetry, and AI services.

### 2. JWT Security Keys
* `JWT_SECRET` / `SECRET_KEY`: Cryptographic signing keys (must match across services).
* `JWT_EXPIRES_IN`: Access token expiration duration (default: `24h`).
* `ACCESS_TOKEN_EXPIRE_MINUTES`: API token lifespan (default: `300`).

### 3. SMTP Mail Configs
* `MAIL_USERNAME` / `MAIL_PASSWORD`: SMTP credentials for email verifications.
* `MAIL_PORT` / `MAIL_SERVER`: SMTP server endpoint details.

### 4. Microservice Database Connection Strings
* `AUTH_DATABASE_URL`: `mysql+pymysql://thathsara:BandaPutha@db/grabber_auth`
* `ROBOT_DATABASE_URL`: `mysql+aiomysql://thathsara:BandaPutha@db/grabber_robot`
* `TELEMETRY_DATABASE_URL`: `mysql+aiomysql://thathsara:BandaPutha@db/grabber_telemetry`
* `AI_DATABASE_URL`: `mysql+pymysql://thathsara:BandaPutha@db/grabber_ai`

### 5. MQTT Broker settings
* `MQTT_BROKER` / `MQTT_PORT`: Connection details for the Mosquitto broker.
* `MQTT_USERNAME` / `MQTT_PASSWORD`: Authentication credentials for broker access.

---

## 🚀 Deployment Instructions

### 1. Local Development Stack (Docker Compose)
Start the entire backend stack, including databases, microservices, and monitoring tools:
```bash
# Start all containers in detatched mode
docker compose up -d
```

#### Accessing Administrative Dashboards:
* **API Gateway**: `http://localhost:8000`
* **Auth Service**: `http://localhost:8001`
* **Robot Service**: `http://localhost:8002`
* **Telemetry Service**: `http://localhost:8003`
* **AI Service**: `http://localhost:8004`
* **Prometheus**: `http://localhost:9090`
* **Grafana**: `http://localhost:3001` (Default credentials: `admin` / `admin`)
* **phpMyAdmin**: `http://localhost:8081` (Database administration interface)
* **Adminer**: `http://localhost:8080` (Alternative database client)

### 2. Local VM Hosting & Public Tunneling
If you want to host the platform on a local Ubuntu Server VM and access it securely over the internet:
* Refer to the detailed setup guide: [docs/ubuntu-vm-setup-tunneling.md](docs/ubuntu-vm-setup-tunneling.md) for VM sizing, Netplan settings, Docker setup, Cloudflare Tunnels/Ngrok configurations, and ESP32 firmware updates.

---

### 3. AWS Cloud Hosting & GitOps Pipeline
If you want to host the platform in the AWS Cloud with automated CI/CD:
* Refer to the detailed guide: [docs/aws-cloud-hosting-gitops.md](docs/aws-cloud-hosting-gitops.md) for theoretical service mappings (RDS, ElastiCache, EKS, ALB), AWS Terraform code, Jenkins CI Pipelines, and ArgoCD (GitOps) Continuous Deployment configurations.

---

### 4. Cloud/Cluster Kubernetes Deployments (Terraform)
Deploy the system to a Kubernetes cluster:
```bash
# Navigate to k8s directory
cd terraform/k8s

# Initialize Terraform providers
terraform init

# Review execution plan
terraform plan

# Deploy infrastructure to the cluster
terraform apply -auto-approve
```

---

## 🔗 Related Grabber Repositories

| Repository | Purpose |
|---|---|
| [`01-grabber-architecture`](https://github.com/thathsarabandara/01-grabber-architecture) | System blueprints, MQTT schemas, and database designs |
| [`02-grabber-firmware`](https://github.com/thathsarabandara/02-grabber-firmware) | ESP32 main controller firmware and servo controls |
| [`03-grabber-mobile-app`](https://github.com/thathsarabandara/03-grabber-mobile-app) | Flutter app remote teleoperation HUD |
| [`05-grabber-api-gateway`](https://github.com/thathsarabandara/05-grabber-api-gateway) | Inbound router proxying app REST & WebSocket requests |
| [`06-grabber-auth-service`](https://github.com/thathsarabandara/06-grabber-auth-service) | Service managing user profiles, image updates, and JWT sessions |
| [`07-grabber-robot-service`](https://github.com/thathsarabandara/07-grabber-robot-service) | Service processing joint commands and homing schedules |
| [`08-grabber-telemetry-service`](https://github.com/thathsarabandara/08-grabber-telemetry-service) | Core service publishing live telemetry and webcam captures |
| [`09-grabber-ai-service`](https://github.com/thathsarabandara/09-grabber-ai-service) | Engine orchestrating autonomous sorting tasks and YOLO models |
| [`10-grabber-mqtt-server`](https://github.com/thathsarabandara/grabber-mqtt-service) | Eclipse Mosquitto MQTT broker configuration and credentials |

---

<div align="center">
  <sub>Part of the <strong>Grabber</strong> AI-Powered Industrial Robotic Arm Platform</sub>
</div>
