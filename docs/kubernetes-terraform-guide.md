# Grabber Platform DevOps Infrastructure

A comprehensive technical guide to the Kubernetes, Terraform, Helm, Cloudflare Tunnel, Prometheus, Grafana, Bash automation, and Makefile design used by the Grabber robotics platform.

This repository is designed for a **single-node Ubuntu VM running k3s**. It deploys application microservices, data services, monitoring, ingress routing, and secure public access through an outbound Cloudflare Tunnel. The infrastructure is defined declaratively with Kubernetes manifests, Helm values, and Terraform modules, while operational workflows are exposed through Bash scripts and a root Makefile.

---

## Table of Contents

1. [Platform Architecture](#platform-architecture)
2. [Kubernetes Foundations](#kubernetes-foundations)
   - [Namespaces](#1-namespaces)
   - [Pods and Deployments](#2-pods-and-deployments)
   - [Services](#3-services)
   - [ConfigMaps and Secrets](#4-configmaps-and-secrets)
   - [StatefulSets and Persistent Storage](#5-statefulsets-and-persistent-storage)
   - [Ingress](#6-ingress)
   - [NetworkPolicies](#7-networkpolicies)
   - [ServiceMonitors and Alert Rules](#8-servicemonitors-and-alert-rules)
   - [Cloudflare Tunnel and Edge Security](#9-cloudflare-tunnel-and-edge-security)
   - [Prometheus and Grafana](#10-prometheus-and-grafana)
   - [Operations Automation and Bash](#11-operations-automation-and-bash)
   - [Helm Package Management](#12-helm-package-management)
3. [Terraform Infrastructure as Code](#terraform-infrastructure-as-code)
   - [Terraform and Providers](#1-terraform-and-providers)
   - [Variables, Locals, and Variable Files](#2-variables-locals-and-variable-files)
   - [Terraform Modules](#3-terraform-modules)
   - [Terraform Helm Provider](#4-terraform-helm-provider)
   - [Cloudflare DNS Automation](#5-cloudflare-dns-automation)
   - [State, Backends, and Outputs](#6-state-backends-and-outputs)
4. [Makefile Command Interface](#makefile-command-interface)
5. [End-to-End Deployment Flow](#end-to-end-deployment-flow)
6. [Security and Operational Notes](#security-and-operational-notes)
7. [Referenced Repository Files](#referenced-repository-files)
8. [Concept Coverage](#concept-coverage)

---

## Platform Architecture

The platform separates workloads into dedicated Kubernetes namespaces and exposes only the ingress layer through a Cloudflare Tunnel.

```text
Public User / Remote Robot Controller
                |
                v
        Cloudflare Edge Proxy
        TLS termination + DNS
                |
                v
     Outbound Cloudflare Tunnel
       cloudflared Pod in k3s
                |
                v
      NGINX Ingress Controller
                |
                v
           API Gateway
                |
      +---------+---------+---------+
      |         |         |         |
      v         v         v         v
    Auth      Robot   Telemetry     AI
   Service   Service   Service    Service
      |         |         |         |
      +---------+---------+---------+
                |
      +---------+----------+
      |                    |
      v                    v
    MySQL             Redis / MQTT

Prometheus <--- ServiceMonitors and /metrics endpoints
    |
    v
Grafana dashboards and alert visualization
```

### Namespace Layout

| Namespace | Responsibility |
|---|---|
| `robot-platform` | Application microservices, database, and message broker |
| `monitoring` | Prometheus, Grafana, dashboards, and alert rules |
| `ingress-nginx` | NGINX Ingress Controller |
| `cloudflare` | Cloudflare Tunnel connector (`cloudflared`) |

The intended request path is:

```text
Cloudflare Edge
  -> cloudflared
  -> ingress-nginx-controller.ingress-nginx.svc.cluster.local:80
  -> Kubernetes Ingress rule
  -> internal ClusterIP Service
  -> application Pod
```

---

# Kubernetes Foundations

## 1. Namespaces

### What Is a Namespace?

A Kubernetes Namespace divides cluster resources between multiple users, projects, or environments. It can be understood as a **virtual cluster inside the physical Kubernetes cluster**.

### Why Namespaces Are Used

- **Isolation:** Pods, Services, Deployments, and other resources in one namespace are logically separated from resources in another namespace.
- **Access control:** Permissions can be restricted so a developer can modify resources only in an assigned namespace.
- **Resource quotas:** CPU and memory consumption can be limited per namespace so one workload cannot consume all VM resources.
- **Name-collision prevention:** A Service named `mysql` can exist in namespace A while another Service named `mysql` exists in namespace B without conflict.

### Applied Example: `platform-namespaces.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: robot-platform
  labels:
    name: robot-platform
    security: platform-core
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    name: monitoring
```

### Field Explanation

- `apiVersion: v1` tells Kubernetes which API schema version is used. Namespace resources use the core `v1` API.
- `kind: Namespace` specifies the resource type being created.
- `metadata` contains information that uniquely identifies and organizes the object.
- `metadata.name` defines the namespace name, such as `robot-platform` or `monitoring`.
- `metadata.labels` stores key-value metadata used to organize, group, or select resources. The `name: robot-platform` label can later be referenced by network policies or other selectors that allow or deny traffic between namespaces.
- `---` is the YAML document separator and allows several Kubernetes resources to be defined in one file.

The complete namespace design creates four logical cluster areas:

- `robot-platform` for microservices, MySQL, Redis, and the broker.
- `monitoring` for Prometheus and Grafana.
- `ingress-nginx` for the ingress router.
- `cloudflare` for the Cloudflare Tunnel connector.

---

## 2. Pods and Deployments

### What Is a Pod?

A Pod is the smallest deployable unit in Kubernetes. It represents a running process in the cluster and can contain one or more containers that share:

- Storage volumes
- A network IP address
- The same port space

**Analogy:** A container is a tenant, while a Pod is the shared apartment.

### What Is a Deployment?

Standalone Pods are rarely created directly in production. When a standalone Pod crashes or its host fails, that Pod is lost. A Deployment is a controller that manages a group of identical Pods and provides:

- **Self-healing:** When a Pod dies or is removed, the Deployment creates a replacement.
- **Scaling:** The number of Pod replicas can be increased or decreased.
- **Rolling updates:** New image versions can be introduced Pod by Pod to reduce downtime.

### Applied Example: Authentication Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: robot-platform
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
        - name: auth-service
          image: ghcr.io/thathsarabandara/grabber-auth-service:1.0.0
          ports:
            - containerPort: 8000
```

### Field Explanation

- `metadata.namespace: robot-platform` deploys the resource inside the isolated platform namespace.
- `spec.replicas: 1` requests one Pod instance, which is appropriate for the current single-node VM design.
- `spec.selector.matchLabels` tells the Deployment which Pods it manages. Here, it manages Pods labeled `app: auth-service`.
- `spec.template` is the Pod blueprint used whenever Kubernetes creates or replaces an instance.
- `spec.template.metadata.labels` applies the label that must match the Deployment selector.
- `spec.template.spec.containers` defines the containers in the Pod.
- `image` points to the versioned container image in GitHub Container Registry (GHCR).
- `ports.containerPort: 8000` documents the port on which the application listens inside the container.

---

## 3. Services

### Why a Service Is Required

Kubernetes Pods are volatile. They are created, destroyed, and recreated dynamically, and a restarted Pod normally receives a different IP address. Therefore, `api-gateway` cannot safely depend on the direct IP address of `auth-service`.

A Kubernetes Service provides a stable internal IP address and DNS hostname and forwards requests to a changing set of matching Pods.

### Service Types

- **ClusterIP:** The default type. It exposes the Service only inside the cluster and is suitable for databases and backend APIs.
- **NodePort:** Exposes a fixed port on every cluster node. The Service can be reached using `<NodeIP>:<NodePort>`.
- **LoadBalancer:** Requests an external load balancer from a supported cloud provider such as AWS or GCP.

### Applied Example: Authentication Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  namespace: robot-platform
spec:
  ports:
    - name: http
      port: 8000
      targetPort: 8000
  selector:
    app: auth-service
  type: ClusterIP
```

### Field Explanation

- `metadata.name: auth-service` registers the internal DNS name. Other Pods can call the service through `http://auth-service:8000` while they are in the same namespace.
- `spec.type: ClusterIP` keeps the authentication service private and prevents direct internet exposure.
- `spec.ports[].port: 8000` is the port used by clients connecting to the Service.
- `spec.ports[].targetPort: 8000` is the destination port on the selected Pods.
- `spec.selector.app: auth-service` sends traffic to Pods carrying the `app: auth-service` label.

When the Deployment is scaled to five replicas, the Service automatically distributes requests across all five Pods.

---

## 4. ConfigMaps and Secrets

Container images should remain portable and should not contain environment-specific configuration or credentials. Kubernetes separates code from runtime configuration using ConfigMaps and Secrets.

### ConfigMap

A ConfigMap stores **non-confidential configuration** as key-value pairs.

Examples include:

- Server ports
- Database names
- Internal service URLs
- Feature flags

Pods can consume ConfigMap values as environment variables or as files mounted into the container.

### Secret

A Secret stores sensitive values such as:

- Database passwords
- JWT keys
- API tokens
- SSL certificates

Kubernetes Secret values are commonly represented in base64 form in manifests. Kubernetes decodes the selected value before injecting it into a container as a normal environment variable.

> **Security note:** Base64 is encoding, not encryption. Production clusters should also use encryption at rest, restrictive RBAC, and preferably an external secret-management workflow.

### Applied Example: `configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-gateway-config
  namespace: robot-platform
data:
  NODE_ENV: "production"
  AUTH_SERVICE_URL: "http://auth-service:8000"
```

### Loading ConfigMap and Secret Values into a Deployment

```yaml
env:
  # A. Reading from a ConfigMap
  - name: AUTH_SERVICE_URL
    valueFrom:
      configMapKeyRef:
        name: api-gateway-config
        key: AUTH_SERVICE_URL

  # B. Reading from a Secret
  - name: REDIS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: redis-secrets
        key: redis-password
```

### Field Explanation

- `configMapKeyRef` instructs Kubernetes to read the `AUTH_SERVICE_URL` key from `api-gateway-config`.
- `secretKeyRef` instructs Kubernetes to read `redis-password` from `redis-secrets`.
- Kubernetes decodes the Secret value and makes it available to the container as the `REDIS_PASSWORD` environment variable.

---

## 5. StatefulSets and Persistent Storage

Stateless applications such as an API Gateway can be replaced without data loss because they should not rely on files stored on their local container filesystem. Stateful systems such as MySQL and Mosquitto MQTT must preserve data across Pod restarts.

### StatefulSet vs. Deployment

- **Deployment:** Creates interchangeable Pods with generated names such as `api-gateway-5cbd47`. Replicas have no stable identity relationship.
- **StatefulSet:** Creates Pods with ordered, stable identities such as `mysql-0` and `mysql-1`. Each Pod can receive dedicated persistent storage that remains associated with that identity when the Pod is rescheduled.

### PersistentVolume, PersistentVolumeClaim, and StorageClass

- **PersistentVolume (PV):** Physical or virtual storage available to the cluster, such as a VM directory or a cloud disk.
- **PersistentVolumeClaim (PVC):** A workload request for storage capacity and an access mode. Kubernetes binds the claim to a matching volume.
- **StorageClass:** Defines dynamic provisioning behavior. When a PVC is created, the StorageClass can automatically create a matching PV.

### Applied Example: MySQL `statefulset.yaml`

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: robot-platform
spec:
  serviceName: mysql
  replicas: 1
  template:
    spec:
      containers:
        - name: mysql
          image: mysql:8.4
          volumeMounts:
            - name: mysql-data
              mountPath: /var/lib/mysql
  volumeClaimTemplates:
    - metadata:
        name: mysql-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: local-path
        resources:
          requests:
            storage: 10Gi
```

### Field Explanation

- `kind: StatefulSet` gives the database Pod a stable hostname such as `mysql-0`.
- `serviceName: mysql` identifies the governing Service used for stable StatefulSet network identities.
- `volumeMounts[].name: mysql-data` references the volume assigned to the Pod.
- `mountPath: /var/lib/mysql` mounts persistent storage where MySQL writes its database files.
- `volumeClaimTemplates` creates a unique PVC for each StatefulSet Pod instead of sharing one volume among unrelated replicas.
- `accessModes: ["ReadWriteOnce"]` allows read-write mounting by one node.
- `storageClassName: local-path` uses the default k3s local-path provisioner.
- The local-path provisioner creates storage under `/var/lib/rancher/k3s/storage/` on the VM host and binds it to the claim.
- `resources.requests.storage: 10Gi` requests 10 GiB of storage for the database claim.

If `mysql-0` crashes or is deleted, Kubernetes recreates `mysql-0` and reattaches the same `mysql-data-mysql-0` persistent volume, preventing database data loss.

---

## 6. Ingress

ClusterIP Services are accessible only inside the cluster. An external browser or remote robot controller needs an HTTP/HTTPS routing layer to reach the internal API.

### What Is an Ingress?

An Ingress is a Kubernetes API object that declares external HTTP and HTTPS routing rules. Rules can match hostnames and URL paths and forward traffic to internal Services.

### Ingress Controller

An Ingress resource does not process traffic by itself. An **Ingress Controller** must watch Ingress resources and configure a reverse proxy accordingly.

This platform uses the **NGINX Ingress Controller**, installed through Helm. The controller observes Ingress objects, reads their routing rules, and proxies matching requests.

### Applied Example: `api-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: robot-platform
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
spec:
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-gateway
                port:
                  number: 8000
```

### Field Explanation

- `metadata.annotations` configures advanced NGINX reverse-proxy behavior.
- `kubernetes.io/ingress.class: "nginx"` assigns the route to the NGINX Ingress Controller.
- `nginx.ingress.kubernetes.io/proxy-body-size: "100m"` permits request bodies up to 100 MB, which is important for webcam capture or media uploads.
- `nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"` sets the upstream connection timeout.
- `nginx.ingress.kubernetes.io/proxy-read-timeout: "600"` extends the read timeout to ten minutes for long-running API operations or WebSocket connections.
- `nginx.ingress.kubernetes.io/proxy-send-timeout: "600"` extends the upstream send timeout to ten minutes.
- `spec.rules` declares hostname-based routing.
- `host: api.example.com` matches requests whose HTTP Host header is `api.example.com`.
- `path: /` with `pathType: Prefix` matches every path beginning with `/`.
- `backend.service.name: api-gateway` forwards matching requests to the internal `api-gateway` Service.
- `backend.service.port.number: 8000` selects Service port `8000`.

---

## 7. NetworkPolicies

By default, Kubernetes networking commonly allows Pods to communicate freely. In a production environment, this is risky: a compromised public-facing frontend could connect directly to a private database.

### What Is a NetworkPolicy?

A NetworkPolicy defines which Pods may communicate with selected Pods and endpoints. It acts as a container-level firewall policy.

### Traffic Directions

- **Ingress:** Incoming traffic to selected Pods.
- **Egress:** Outgoing traffic from selected Pods.

### Default-Deny Ingress Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: robot-platform
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

- `podSelector: {}` matches every Pod in `robot-platform`.
- `policyTypes: [Ingress]` denies incoming traffic by default once enforced by the cluster networking implementation.
- The resulting security model is deny-by-default: communication must be explicitly permitted.

### Restricting MySQL Access

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-mysql-access
  namespace: robot-platform
spec:
  podSelector:
    matchLabels:
      app: mysql
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - auth-service
                  - robot-service
                  - telemetry-service
                  - ai-service
      ports:
        - protocol: TCP
          port: 3306
```

### Field Explanation

- `spec.podSelector.matchLabels.app: mysql` targets traffic entering MySQL Pods.
- `ingress.from` defines approved traffic sources.
- `podSelector.matchExpressions` permits Pods whose `app` label is one of:
  - `auth-service`
  - `robot-service`
  - `telemetry-service`
  - `ai-service`
- `ingress.ports` limits the allowed traffic to TCP port `3306`.

With this policy, a public-facing frontend Pod cannot connect directly to MySQL on port `3306`; the Kubernetes network layer blocks the connection.

---

## 8. ServiceMonitors and Alert Rules

The platform uses the Prometheus Operator pattern instead of manually editing one central Prometheus configuration file. Kubernetes Custom Resources describe scrape targets and alert rules, and the operator converts them into Prometheus configuration.

### ServiceMonitor

A ServiceMonitor tells Prometheus how to discover and scrape application metrics.

It specifies:

- The target Service through labels
- The named Service port
- The metrics path, such as `/metrics`
- The scrape interval

The Prometheus Operator detects the resource and updates Prometheus automatically.

### PrometheusRule

A PrometheusRule defines alerts using Prometheus Query Language (PromQL). When an expression becomes true—for example, a service is offline or memory use crosses a threshold—Prometheus creates an alert and sends it to Alertmanager.

### Applied Example: `service-monitor.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-gateway
  namespace: robot-platform
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: api-gateway
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
```

### Field Explanation

- `metadata.labels.release: prometheus` helps the Prometheus Operator select this monitor.
- `spec.selector.matchLabels.app: api-gateway` finds the `api-gateway` Service.
- `endpoints[].port: http` selects the Service port named `http`.
- `endpoints[].path: /metrics` defines the metrics endpoint.
- `endpoints[].interval: 15s` scrapes metrics every 15 seconds.

### Applied Example: `platform-alert-rules.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: platform-alert-rules
  namespace: monitoring
spec:
  groups:
    - name: platform-health-alerts
      rules:
        - alert: ServiceUnavailable
          expr: up{job=~"auth-service|robot-service|api-gateway"} == 0
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: "Service instance {{ $labels.job }} is down"
```

### Field Explanation

- `expr` contains the PromQL expression. The `up` metric is `1` when a scrape target is reachable and `0` when it is unavailable.
- The expression checks `auth-service`, `robot-service`, and `api-gateway` targets for an `up` value of `0`.
- `for: 2m` keeps the alert pending until the condition has remained true for two minutes, reducing false alarms during brief restarts.
- `labels.severity: critical` classifies the alert as critical.
- `annotations.summary` provides a templated human-readable message for developers.

---

## 9. Cloudflare Tunnel and Edge Security

Traditional self-hosting often requires router port forwarding for ports `80` and `443`, exposing the VM public IP to scans, DDoS traffic, and intrusion attempts.

Cloudflare Tunnel avoids inbound exposure by creating an encrypted, outbound connection from the cluster to the Cloudflare edge.

### How the Tunnel Works

1. The `cloudflared` daemon runs as a Pod inside k3s.
2. It establishes an outbound connection to Cloudflare servers, which is allowed by most firewalls.
3. Public users connect to Cloudflare edge hostnames such as `dashboard.example.com`.
4. Cloudflare sends traffic through the active tunnel into the local cluster.
5. No inbound ports need to be opened on the host or home router.
6. The VM can remain protected by UFW rules that allow SSH only from the private home network.

### Applied Example: Cloudflare Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
  namespace: cloudflare
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloudflared
  template:
    metadata:
      labels:
        app: cloudflared
    spec:
      containers:
        - name: cloudflared
          image: cloudflare/cloudflared:2024.6.1
          args:
            - tunnel
            - --no-autoupdate
            - run
          env:
            - name: TUNNEL_TOKEN
              valueFrom:
                secretKeyRef:
                  name: cloudflare-tunnel-token
                  key: tunnel-token
```

### Field Explanation

- `args: [tunnel, --no-autoupdate, run]` starts `cloudflared` in tunnel client daemon mode.
- `TUNNEL_TOKEN` is read from the `cloudflare-tunnel-token` Secret.
- The token is generated in the Cloudflare Zero Trust dashboard and uniquely links the connector to the tunnel and DNS zone.

### Internal Tunnel Origin

In Cloudflare Zero Trust, the hostname—for example, `*.example.com`—is configured to forward to the internal NGINX Ingress Controller at:

```text
http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80
```

An external request therefore follows this route:

```text
Cloudflare Edge
  -> Cloudflare Tunnel
  -> NGINX Ingress inside k3s
  -> hostname/path rule
  -> correct Kubernetes Service
  -> application Pod
```

---

## 10. Prometheus and Grafana

### Roles

- **Prometheus** handles metrics ingestion and time-series storage. It discovers targets through ServiceMonitors, periodically calls their metrics endpoints, and stores the collected data.
- **Grafana** provides visualization. It connects to Prometheus as a data source and queries metrics to render dashboards.

### Infrastructure-as-Code Dashboards

Dashboards created only through the Grafana UI are difficult to reproduce and may be lost if storage is not persisted. Grafana provisioning makes dashboards declarative:

1. Dashboard JSON is stored in Kubernetes ConfigMaps.
2. A Grafana sidecar container continuously scans for ConfigMaps carrying a specific label, such as `grafana_dashboard: "1"`.
3. The sidecar copies matching JSON files into Grafana's dashboard directory.
4. Grafana loads and displays them automatically.

### Applied Example: `platform-dashboards.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: platform-dashboards
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  platform-overview.json: |
    {
      "title": "Platform Overview",
      "panels": [
        {
          "title": "System Node CPU Utilization",
          "type": "timeseries",
          "targets": [
            {
              "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode='idle'}[5m])) * 100)"
            }
          ]
        }
      ]
    }
```

### Field Explanation

- `grafana_dashboard: "1"` is the label watched by the Grafana sidecar.
- Every key under `data` represents a dashboard file.
- `platform-overview.json` is copied into Grafana's dashboard directory.
- The example dashboard contains a time-series panel for system node CPU utilization.
- The PromQL expression calculates CPU utilization by subtracting average idle CPU percentage from 100.

### Persisting Grafana Configuration: `monitoring-values.yaml`

```yaml
grafana:
  enabled: true
  persistence:
    enabled: true
    storageClassName: local-path
    size: 5Gi
  admin:
    existingSecret: "grafana-admin-secret"
    adminPasswordKey: "admin-password"
```

### Field Explanation

- `grafana.enabled: true` enables Grafana in the monitoring chart.
- `persistence.enabled: true` attaches a PersistentVolume so user settings, custom permissions, and ad-hoc changes survive Pod restarts.
- `storageClassName: local-path` uses the k3s local-path provisioner.
- `size: 5Gi` requests 5 GiB for Grafana persistence.
- `admin.existingSecret: grafana-admin-secret` avoids hardcoding the administrator password in the values file.
- `adminPasswordKey: admin-password` selects the password key from the Secret created during the `make secrets` workflow.

---

## 11. Operations Automation and Bash

Deploying the complete platform requires several dependent operations:

- Preparing the VM
- Installing required tools
- Creating Secrets
- Deploying ingress and infrastructure components
- Waiting for MySQL and Redis to become ready
- Running database migrations
- Deploying applications
- Deploying monitoring
- Deploying Cloudflare Tunnel

Performing these steps manually is slow and error-prone. The repository therefore uses Bash scripts wrapped by a root Makefile.

### Script Design Principles

#### Idempotency

Running a script repeatedly should produce the same desired state without unnecessary failures. For example, an existing namespace should be reused or safely updated instead of causing the entire process to fail.

#### Strict Error Handling

```bash
set -Eeuo pipefail
```

- `-e`: Exit immediately when a command fails.
- `-E`: Preserve error traps through shell functions, command substitutions, and subshells.
- `-u`: Exit when an unset variable is referenced.
- `-o pipefail`: A pipeline fails if any command in it fails, not only the final command.

For example, when `cmd1 | cmd2` is executed, failure of `cmd1` causes the pipeline to return a failure status.

#### Sequential Dependency Waiting

Application deployment must not continue until infrastructure dependencies such as MySQL, Redis, and ingress are running and healthy.

### Applied Example: `deploy-infrastructure.sh`

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 1. Apply Namespaces
kubectl apply -f "${REPO_ROOT}/kubernetes/namespaces/platform-namespaces.yaml"

# 2. Deploy Ingress Controller via Helm
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  -f "${REPO_ROOT}/helm/ingress-nginx-values.yaml"

# 3. Wait for Ingress Controller to become Ready
echo "Waiting for NGINX Ingress Controller pods to become Ready..."
kubectl rollout status deployment/ingress-nginx-controller \
  -n ingress-nginx \
  --timeout=180s

# 4. Deploy MySQL Database
kubectl apply -f "${REPO_ROOT}/kubernetes/infrastructure/mysql/statefulset.yaml"

# 5. Wait for MySQL StatefulSet rollout
kubectl rollout status statefulset/mysql \
  -n robot-platform \
  --timeout=180s
```

### Operation Explanation

- `SCRIPT_DIR` calculates the absolute directory containing the current script.
- `REPO_ROOT` calculates the repository root relative to the script location.
- Dynamic absolute paths allow scripts and Makefile targets to be launched from any working directory.
- `helm upgrade --install` is idempotent: it installs the release when missing and applies updates when the release already exists.
- `kubectl rollout status` is a dependency guard. It waits until Kubernetes finishes image pulling, startup, and readiness processing before the script continues.
- The ingress Deployment and MySQL StatefulSet each use a `180s` rollout timeout.

---

## 12. Helm Package Management

Deploying complex third-party systems such as NGINX Ingress or Prometheus manually requires maintaining many interconnected resources, including Deployments, Services, RBAC roles, and ServiceAccounts.

### What Is Helm?

Helm is the package manager for Kubernetes. Similar to how `apt` manages Ubuntu packages, Helm installs and manages Kubernetes applications.

### Core Helm Concepts

- **Helm Chart:** A packaged collection of templates describing related Kubernetes resources.
- **Repository:** A registry from which charts are published and downloaded, similar to Docker Hub or an npm registry.
- **Values file (`values.yaml`):** Configuration used to override chart defaults without editing the chart source.
- **Release:** A running installation of a Helm chart in a cluster.

### Applied Example: `ingress-nginx-values.yaml`

```yaml
controller:
  replicaCount: 1
  resources:
    requests:
      cpu: 100m
      memory: 90Mi
    limits:
      cpu: 500m
      memory: 256Mi
  service:
    type: ClusterIP
```

### Field Explanation

- `controller.replicaCount: 1` reduces the controller to one replica for the single Ubuntu VM. Larger production clusters may use three or more replicas.
- `controller.resources.requests` reserves `100m` CPU and `90Mi` memory.
- `controller.resources.limits` caps the controller at `500m` CPU and `256Mi` memory to prevent excessive VM resource use.
- `controller.service.type: ClusterIP` keeps the ingress controller private.
- Cloud providers commonly default ingress controllers to public LoadBalancer Services. This platform does not need a public load balancer because all public traffic arrives through the outbound Cloudflare Tunnel.

### Helm Installation Command

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  -f helm/ingress-nginx-values.yaml
```

Helm combines the chart defaults with the values overrides and renders the final Kubernetes manifests.

---

# Terraform Infrastructure as Code

Terraform provides a declarative layer for managing namespaces, Helm releases, storage-related resources, Cloudflare DNS, and shared infrastructure values.

## 1. Terraform and Providers

### What Is Terraform?

Terraform is an open-source Infrastructure-as-Code tool created by HashiCorp. It defines resources—such as virtual networks, DNS records, virtual machines, and Kubernetes namespaces—in declarative configuration files.

**Declarative infrastructure** means describing the required final state. For example, the configuration states that a namespace named `monitoring` must exist, and Terraform determines which create, update, or delete operations are needed.

### What Is a Provider?

Terraform does not directly understand every platform API. Providers are plugins that translate Terraform resources into API calls for a target system.

The robotics platform uses three providers:

- `kubernetes` connects to the k3s cluster and manages resources such as namespaces.
- `helm` installs and manages charts such as NGINX Ingress and Prometheus.
- `cloudflare` manages Cloudflare DNS records.

### Provider Version Declaration: `versions.tf`

```hcl
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.35.0"
    }
  }
}
```

### Field Explanation

- `required_version = ">= 1.8.0"` prevents execution with an incompatible Terraform engine.
- `required_providers` declares provider registry sources and version constraints.
- `source = "hashicorp/kubernetes"` identifies the official Kubernetes provider.
- `source = "cloudflare/cloudflare"` identifies the Cloudflare provider.
- `~> 2.31.0` is a pessimistic constraint: it permits compatible patch releases such as `2.31.1` while preventing a breaking major release such as `3.0.0`.

> The platform also uses the Helm provider. Its declaration should be present in the complete `required_providers` block even though the supplied version example shows only Kubernetes and Cloudflare.

### Provider Authentication: `providers.tf`

```hcl
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "cloudflare" {
  # Automatically picks up CLOUDFLARE_API_TOKEN from environment variables
}
```

### Authentication Explanation

- `config_path` authenticates to k3s using a kubeconfig file, normally `$HOME/.kube/config`.
- The empty Cloudflare provider block reads `CLOUDFLARE_API_TOKEN` from the shell environment.
- Cloudflare API tokens are therefore not hardcoded or committed to Git.

---

## 2. Variables, Locals, and Variable Files

Reusable Terraform configuration must avoid hardcoded domain names, namespace identifiers, environment names, and storage settings.

### Input Variables

Variables define module inputs and can include:

- Type constraints such as `string`, `number`, and `bool`
- Human-readable descriptions
- Default fallback values
- Validation rules

### Local Values

Locals are internally calculated values similar to constants or derived variables in a programming language. They prevent repeated complex expressions and support the DRY principle.

Typical examples include:

- Shared label maps
- Composite URLs
- Tunnel CNAME targets

### Variable Files

A `.tfvars` file assigns real values to input variables during `terraform plan` or `terraform apply`.

The real `terraform.tfvars` should be ignored by Git. Only a `terraform.tfvars.example` template should be committed to show which values are required.

### Applied Example: `variables.tf`

```hcl
variable "platform_namespace" {
  type        = string
  description = "Target namespace for grabber services"
  default     = "robot-platform"
}

variable "root_domain" {
  type        = string
  description = "Root domain mapped on Cloudflare"
}
```

- `platform_namespace` is optional because it has the default value `robot-platform`.
- `root_domain` is mandatory because it has no default. Terraform prompts for it or fails in a non-interactive run when it is not supplied.

### Applied Example: `locals.tf`

```hcl
locals {
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "grabber-platform"
    "environment"                  = var.environment
  }

  tunnel_cname_target = "${var.cloudflare_tunnel_id}.cfargotunnel.com"
}
```

- `common_labels` creates a shared label map.
- `var.environment` is interpolated into the standard environment label.
- `tunnel_cname_target` constructs the Cloudflare Tunnel CNAME target from the tunnel ID.

### Applied Example: `terraform.tfvars.example`

```hcl
platform_namespace = "robot-platform"
root_domain         = "example.com"
```

The operator copies this template to `terraform.tfvars` and replaces example values before planning or applying the infrastructure.

The root Makefile integrates Terraform command targets so operators do not need to remember long `terraform -chdir=...` commands.

---

## 3. Terraform Modules

As infrastructure grows, keeping every resource in one file becomes difficult to maintain. Terraform modules group related resources behind explicit inputs and outputs.

### Module Model

- Every Terraform configuration has a **root module**, which is the directory where Terraform is executed.
- A root module can call **child modules** stored in local directories or remote registries.
- Child-module inputs are declared with variables.
- Child-module outputs expose values to the root module or other dependent modules.

### Namespace Module Output

```hcl
output "platform_namespace_name" {
  value = kubernetes_namespace.platform.metadata[0].name
}
```

This exports the actual name created by the namespace module.

### Root Module Composition: `main.tf`

```hcl
module "namespaces" {
  source = "./modules/namespaces"

  platform_namespace   = var.platform_namespace
  monitoring_namespace = var.monitoring_namespace
  ingress_namespace    = var.ingress_namespace
  cloudflare_namespace = var.cloudflare_namespace
  common_labels        = locals.common_labels
}

module "storage" {
  source = "./modules/storage"

  # Read the output from the namespaces module.
  platform_namespace  = module.namespaces.platform_namespace_name
  storage_class_name  = var.storage_class_name
  backup_storage_size = var.backup_storage_size
  common_labels       = locals.common_labels
}
```

### Composition Explanation

- `source = "./modules/namespaces"` loads the resource definitions from the local namespaces module.
- The namespace module receives the platform, monitoring, ingress, and Cloudflare namespace names plus shared labels.
- The storage module receives `module.namespaces.platform_namespace_name` instead of independently assuming the namespace value.
- Because the storage module references an output of the namespace module, Terraform creates an implicit dependency.
- Terraform creates the namespace first, waits for the dependency to be satisfied, and then creates storage resources such as the PVC in that namespace.

> **Syntax review:** The supplied snippets use `locals.common_labels`. Native Terraform references normally use the singular form `local.common_labels`. Preserve the repository’s intended value, but correct the identifier if the actual configuration uses the standard `locals { ... }` block.

---

## 4. Terraform Helm Provider

Kubernetes manifests are suitable for platform-owned application resources, while third-party suites such as Prometheus Operator and NGINX Ingress may contain thousands of lines of generated resources. These are delegated to Helm.

The Terraform Helm provider manages Helm chart lifecycles through the `helm_release` resource.

### Why Manage Helm with Terraform?

- Helm releases become part of Terraform state.
- Releases can consume values produced by other Terraform modules.
- Terraform can calculate the correct dependency order.
- Chart installation and upgrades become repeatable infrastructure changes.

### Overriding Chart Values

A Helm chart includes defaults. Terraform's `set` block overrides individual values and behaves like Helm CLI `--set` arguments.

### Applied Example: NGINX Ingress `helm_release`

```hcl
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version
  namespace  = var.ingress_namespace
  wait       = true
  timeout    = 300

  set {
    name  = "controller.replicaCount"
    value = "1"
  }

  set {
    name  = "controller.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "controller.metrics.serviceMonitor.namespace"
    value = var.monitoring_namespace
  }
}
```

### Field Explanation

- `repository` and `chart` fetch the official NGINX Ingress chart.
- `version` pins the chart to `var.ingress_nginx_chart_version`.
- `namespace` installs the release into the configured ingress namespace.
- `wait = true` pauses Terraform until the ingress controller reports Ready.
- `timeout = 300` allows up to 300 seconds for the release operation.
- `controller.replicaCount = 1` reduces resource use on the single VM.
- `controller.service.type = ClusterIP` avoids public node exposure and keeps the controller behind Cloudflare Tunnel.
- `controller.metrics.serviceMonitor.namespace` sends the monitoring namespace into the chart, automating the cross-namespace ServiceMonitor linkage.

---

## 5. Cloudflare DNS Automation

After the local services and Cloudflare Tunnel are configured, public hostnames must point to the tunnel endpoint. Terraform automates this instead of requiring manual DNS changes in the Cloudflare dashboard.

### Tunnel CNAME Mapping

A tunnel has a target hostname in this form:

```text
<tunnel-id>.cfargotunnel.com
```

Public names such as:

```text
api.example.com
dashboard.example.com
```

are configured as CNAME records pointing to that tunnel target.

### Proxied Records

With `proxied = true`, also known as Cloudflare's orange-cloud mode:

- The physical public IP address of the VM remains hidden.
- Visitors see Cloudflare edge IP addresses.
- Cloudflare handles browser-facing SSL/TLS certificate issuance and termination at the edge.

### Conditional Creation with `count`

Local or test environments may need to avoid modifying production DNS. Terraform's `count` attribute can act as an if-condition and create either one record or zero records.

### Applied Example: `cloudflare_record`

```hcl
resource "cloudflare_record" "api" {
  count   = var.enable_cloudflare_dns ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = split(".", var.api_domain)[0]
  content = var.tunnel_cname_target
  type    = "CNAME"
  proxied = true
}
```

### Field Explanation

- `count = var.enable_cloudflare_dns ? 1 : 0` creates one record when DNS automation is enabled and no records when it is disabled.
- `zone_id` identifies the Cloudflare zone for the root domain.
- `split(".", var.api_domain)[0]` extracts the first hostname segment. For `api.example.com`, the result is `api`.
- `content = var.tunnel_cname_target` points the CNAME to `<tunnel-id>.cfargotunnel.com`.
- `type = "CNAME"` creates a canonical-name record.
- `proxied = true` enables Cloudflare edge proxying, protection, and SSL termination.

---

## 6. State, Backends, and Outputs

Terraform must remember which declared resources correspond to real resources in Kubernetes, Helm, and Cloudflare.

### Terraform State

`terraform.tfstate` is Terraform's resource mapping database. It records the association between configuration addresses and actual deployed resources.

> **Critical:** State can contain infrastructure metadata and sometimes sensitive values in plaintext. It must never be committed to Git.

### State Locking

Two simultaneous `terraform apply` operations can corrupt or conflict with shared state. State locking prevents multiple operators from modifying the same state at the same time.

### Backends

A backend defines where Terraform stores state.

- **Local backend:** Stores `terraform.tfstate` on the VM. It is simple for testing but unsafe for collaboration and vulnerable to local disk loss.
- **Remote backend:** Stores state in a service such as Amazon S3 or Terraform Cloud, enabling controlled sharing, backups, remote execution, and locking.

### Outputs

Outputs are similar to return values in programming. They expose generated or composed infrastructure information to operators, scripts, and other systems.

### Applied Example: `outputs.tf`

```hcl
output "ingress_internal_origin" {
  value       = locals.ingress_internal_origin
  description = "Target local Ingress Endpoint URL for Cloudflare tunnel mapping"
}

output "public_hostnames" {
  value = [
    var.dashboard_domain,
    var.api_domain
  ]
}
```

The supplied output snippet uses `locals.ingress_internal_origin`; standard Terraform syntax normally references a local value as `local.ingress_internal_origin`. After `make tf-apply`, Terraform prints these values. A script can retrieve an output in JSON form with:

```bash
terraform output -json ingress_internal_origin
```

### Remote Backend Blueprint: `backend.tf.example`

```hcl
# AWS S3 Backend Configuration
# terraform {
#   backend "s3" {
#     bucket         = "grabber-terraform-state-bucket"
#     key            = "environments/local-vm/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "grabber-terraform-lock-table"
#   }
# }
```

### Backend Field Explanation

- `bucket` is the S3 bucket that stores the state file.
- `key` is the state object's path inside the bucket.
- `region` identifies the AWS region.
- `encrypt = true` enables server-side encryption for the state object.
- `dynamodb_table` identifies the locking table so only one state-changing operation proceeds at a time.

---

# Makefile Command Interface

Historically, Makefiles compiled C and C++ projects by evaluating file modification times. In modern DevOps repositories, a Makefile can provide one consistent command interface over Terraform, Kubernetes, Helm, and Bash scripts.

## Why Use a Makefile?

- **Reduced cognitive load:** Operators run `make tf-plan` instead of remembering a long command such as `terraform -chdir=terraform/environments/local-vm plan -var-file=...`.
- **Consistency:** Commands run from the correct directory, with expected arguments and in a controlled order.
- **Phony targets:** `.PHONY` tells Make that target names represent commands rather than real files, so they should always execute.

## Declaring Targets and Help

```makefile
.PHONY: install tf-plan tf-apply deploy restore logs

# The '@' prefix hides the command printout and shows only output text.
help:
	@echo "Grabber Platform DevOps Command Interface"
	@echo "  make deploy        - Run full deployment sequence"
```

- `.PHONY` prevents collisions with files named `install`, `deploy`, `logs`, or similar.
- The `@` prefix hides the command itself and prints only the command output.

## Passing Parameters into Targets

Dynamic Make variables support commands such as:

```bash
make logs SERVICE=api-gateway
make restore BACKUP_FILE=/path/to/backup.sql
```

```makefile
logs:
	@chmod +x scripts/*.sh
	@if [ -z "$(SERVICE)" ]; then \
		echo "Usage: make logs SERVICE=<service-name>"; \
		exit 1; \
	fi
	./scripts/logs.sh $(SERVICE)

restore:
	@chmod +x scripts/*.sh
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Usage: make restore BACKUP_FILE=/path/to/backup.sql"; \
		exit 1; \
	fi
	./scripts/restore-mysql.sh "$(BACKUP_FILE)"
```

### Parameter Validation

- `$(SERVICE)` and `$(BACKUP_FILE)` read values supplied on the Make command line.
- `[ -z "..." ]` tests whether a required value is empty.
- A missing argument prints usage guidance and exits with status code `1`.
- `chmod +x scripts/*.sh` makes automation scripts executable and prevents VM permission errors.

## Deployment Workflow Composition

```makefile
deploy:
	@chmod +x scripts/*.sh
	./scripts/deploy-infrastructure.sh
	./scripts/deploy-applications.sh
	./scripts/deploy-monitoring.sh
	./scripts/deploy-cloudflare.sh
```

`make deploy` runs the workflow in sequence:

1. Deploy infrastructure.
2. Deploy application workloads.
3. Deploy Prometheus and Grafana monitoring.
4. Deploy the Cloudflare Tunnel connector.

When a step fails, Make stops the workflow, leaving the current cluster state available for debugging.

---

# End-to-End Deployment Flow

The complete repository workflow is designed around explicit ordering and readiness checks.

## Infrastructure Phase

1. Create or update the namespaces:
   - `robot-platform`
   - `monitoring`
   - `ingress-nginx`
   - `cloudflare`
2. Install the NGINX Ingress Controller through Helm.
3. Wait for `deployment/ingress-nginx-controller` to become Ready.
4. Deploy MySQL as a StatefulSet.
5. Provision persistent storage with the `local-path` StorageClass.
6. Wait for `statefulset/mysql` to become Ready.
7. Deploy additional infrastructure such as Redis and Mosquitto MQTT.
8. Create required Secrets and ConfigMaps.

## Application Phase

1. Deploy the API Gateway.
2. Deploy `auth-service`.
3. Deploy `robot-service`.
4. Deploy `telemetry-service`.
5. Deploy `ai-service`.
6. Expose internal components through ClusterIP Services.
7. Apply Ingress routes.
8. Apply default-deny and explicit allow NetworkPolicies.

## Monitoring Phase

1. Install the Prometheus Operator stack.
2. Apply ServiceMonitors for application Services.
3. Apply PrometheusRule alert definitions.
4. Provision Grafana dashboards from labeled ConfigMaps.
5. Persist Grafana state in a 5 GiB local-path PVC.
6. Load Grafana administrator credentials from `grafana-admin-secret`.

## Public Access Phase

1. Deploy the `cloudflared` connector in the `cloudflare` namespace.
2. Load the tunnel token from `cloudflare-tunnel-token`.
3. Establish an outbound-only connection to Cloudflare.
4. Map public hostnames to `<tunnel-id>.cfargotunnel.com` with proxied CNAME records.
5. Route tunnel traffic to the private NGINX Service at:

```text
http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80
```

6. Let the Ingress Controller route requests to the correct ClusterIP Service.

## Terraform Phase

1. Initialize providers and the selected backend.
2. Validate input variables.
3. Load values from `terraform.tfvars`.
4. Create namespaces through the namespace module.
5. Pass namespace outputs into dependent modules such as storage.
6. Install Helm releases with explicit wait and timeout settings.
7. Optionally create Cloudflare DNS records.
8. Save resource mappings to Terraform state.
9. Print outputs such as `ingress_internal_origin` and public hostnames.

---

# Security and Operational Notes

## Network Exposure

- Application Services use `ClusterIP` and are not directly exposed to the internet.
- NGINX Ingress also uses `ClusterIP` because Cloudflare Tunnel reaches it from inside the cluster.
- No router forwarding for ports `80` or `443` is required.
- UFW can restrict SSH access to the private home network.
- Cloudflare proxying hides the VM's physical public IP.

## Secrets

- Do not store database passwords, JWT keys, API tokens, tunnel tokens, or Grafana administrator passwords in Git.
- Read Cloudflare API credentials from `CLOUDFLARE_API_TOKEN`.
- Read runtime credentials through Kubernetes `secretKeyRef`.
- Do not treat base64 as encryption.

## Terraform State

- Never commit `terraform.tfstate` or state backups.
- Use a remote backend for collaboration.
- Enable encryption and locking.
- Protect backend credentials through environment variables or a secure identity mechanism.

## Storage

- MySQL uses a StatefulSet and dedicated PVC.
- MySQL data is mounted at `/var/lib/mysql`.
- k3s `local-path` storage is created under `/var/lib/rancher/k3s/storage/`.
- Local-path persistence protects against Pod replacement but does not protect against complete VM disk loss; backups remain necessary.

## Reliability

- Deployments provide self-healing, scaling, and rolling updates.
- StatefulSets provide stable Pod identities and storage association.
- `kubectl rollout status` prevents dependent phases from running too early.
- Prometheus waits two minutes before firing `ServiceUnavailable`, reducing false alarms caused by brief restarts.

## Resource Efficiency

The configuration is optimized for a single Ubuntu VM:

- NGINX Ingress replicas: `1`
- NGINX CPU request: `100m`
- NGINX memory request: `90Mi`
- NGINX CPU limit: `500m`
- NGINX memory limit: `256Mi`
- MySQL storage request: `10Gi`
- Grafana storage request: `5Gi`

---

# Referenced Repository Files

The source material references the following files and configuration areas:

```text
Makefile

kubernetes/
├── namespaces/
│   └── platform-namespaces.yaml
├── infrastructure/
│   └── mysql/
│       └── statefulset.yaml
└── ...

helm/
├── ingress-nginx-values.yaml
└── monitoring-values.yaml

scripts/
├── deploy-infrastructure.sh
├── deploy-applications.sh
├── deploy-monitoring.sh
├── deploy-cloudflare.sh
├── logs.sh
└── restore-mysql.sh

terraform/
├── versions.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── backend.tf.example
└── modules/
    ├── namespaces/
    │   └── outputs.tf
    └── storage/

Referenced Kubernetes manifest names:
├── deployment.yaml
├── service.yaml
├── configmap.yaml
├── statefulset.yaml
├── api-ingress.yaml
├── network-policies.yaml
├── service-monitor.yaml
├── platform-alert-rules.yaml
└── platform-dashboards.yaml
```

Some generic filenames such as `deployment.yaml` occur in several component directories—for example, the authentication service and Cloudflare connector—and should remain scoped to their owning component folder.

---

# Concept Coverage

This README consolidates the full walkthrough of:

1. Kubernetes Namespaces
2. Pods
3. Deployments
4. Services and Service types
5. ConfigMaps
6. Secrets
7. StatefulSets
8. PersistentVolumes
9. PersistentVolumeClaims
10. StorageClasses
11. Ingress resources
12. NGINX Ingress Controller
13. NetworkPolicies
14. ServiceMonitors
15. PrometheusRules and PromQL alerts
16. Cloudflare Tunnel
17. Prometheus metrics ingestion
18. Grafana provisioning and persistence
19. Bash idempotency and strict error handling
20. Sequential rollout readiness checks
21. Helm charts, repositories, values, and releases
22. Terraform providers
23. Terraform variables, locals, and `.tfvars`
24. Terraform root and child modules
25. Implicit Terraform dependencies
26. Terraform-managed Helm releases
27. Cloudflare CNAME and proxied DNS automation
28. Conditional resources with `count`
29. Terraform state and state locking
30. Local and remote Terraform backends
31. Terraform outputs
32. Makefile phony targets
33. Makefile parameter validation
34. Multi-stage deployment composition

The result is a private-by-default, repeatable DevOps architecture for running the Grabber robotics platform on a local k3s VM while exposing selected HTTP services securely through Cloudflare.