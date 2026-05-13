# ⚙️ Grabber DevOps & Infrastructure

> **Repository `10`** · The automation and operations hub for the Grabber platform. Contains deployment manifests, CI/CD workflows, Docker configurations, and infrastructure-as-code.

[![Ops](https://img.shields.io/badge/Ops-Docker%20%7C%20GitHub%20Actions-2496ED?logo=docker)]()
[![Env](https://img.shields.io/badge/Env-Production%20%7C%20Staging%20%7C%20Dev-informational)]()
[![Status](https://img.shields.io/badge/Status-Planned-yellow)]()

---

## 🧭 What Is This Repository?

This repository manages the lifecycle of the entire Grabber application suite. It handles how services are built, tested, and deployed to various environments (Local, Staging, Cloud).

**Why a separate Infrastructure repo?**
Deployment automation, release workflows, and environment-specific configurations should live outside application runtime services to ensure a "Separation of Concerns" between code and operations.

---

## 📦 Module Structure

```
10-grabber-devops-infras/
├── docker/                ← Dockerfiles for backend services & support containers
├── compose/               ← Local development & integration stack definitions
├── deploy/                ← Kubernetes manifests or cloud deployment scripts
├── ci-cd/                 ← GitHub Actions for automated testing and releases
├── monitoring/            ← Prometheus/Grafana provisioning & alert rules
└── docs/                  ← Infrastructure runbooks and operational notes
```

---

## 🛠️ Infrastructure Stack

| Component | Tech |
|---|---|
| **Containerization** | Docker, Docker Compose |
| **CI / CD** | GitHub Actions |
| **Reverse Proxy** | Nginx / Traefik (Configured in 05) |
| **Database** | PostgreSQL, Redis (Containerized) |
| **Object Storage** | MinIO (Local) / S3 (Cloud) |
| **Message Broker** | Mosquitto (MQTT) |

---

## 🚀 Deployment Flows

### Local Development
To spin up the entire backend stack locally:
```bash
git clone https://github.com/thathsarabandara/10-grabber-devops-infras.git
cd 10-grabber-devops-infras/compose
docker compose up -d
```
This starts the databases (PostgreSQL, Redis), the MQTT broker, and the mock services.

### Continuous Integration (CI)
Every push to any `grabber-*` repository triggers:
1. **Linting**: Ensuring code style consistency.
2. **Testing**: Running unit and integration tests.
3. **Build**: Creating a new Docker image.
4. **Push**: Uploading images to the GitHub Container Registry (GHCR).

---

## 📊 Monitoring & Alerts
This repository provisions the **Prometheus** and **Grafana** instances that monitor all other services. It defines the "Service Level Objectives" (SLOs) and sends alerts (Slack/Email) if a robot goes offline unexpectedly or a service fails.

---

## 🔗 Related Repositories
| Repo | Role |
|---|---|
| [`01-grabber-architecture`](../01-grabber-architecture) | Infrastructure ownership and governance rules |
| [`05-grabber-api-gateway`](../05-grabber-api-gateway) | The gateway managed by this infrastructure |
| **All Services (02-09)** | These are the apps built and deployed by this repo |

---
<div align="center">
  <sub>Part of the <strong>Grabber</strong> AI-Powered Industrial Robotic Arm Platform</sub>
</div>
