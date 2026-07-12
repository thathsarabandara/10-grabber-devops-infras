# Observability and Monitoring Stack

This document details how metrics collection, alerting, and dashboard visualization are structured.

## Metrics Scraper (Prometheus)

All platform workloads expose metrics at the `/metrics` endpoint. The Prometheus Operator automatically scrapes these endpoints using **ServiceMonitors**:
- The ServiceMonitors are declared inside each application folder (e.g. [api-gateway service-monitor](file:///home/thathsara/Desktop/Thathsara/Project/Grabber/11-grabber-devops-infras/kubernetes/applications/api-gateway/service-monitor.yaml)).
- The `kube-prometheus-stack` values file ([monitoring-values.yaml](file:///home/thathsara/Desktop/Thathsara/Project/Grabber/11-grabber-devops-infras/helm/monitoring-values.yaml)) is configured with `serviceMonitorSelectorNilUsesHelmValues: false`, enabling discovery across namespaces.

---

## Alert Rules

Alerts are separated into three categories under `monitoring/alert-rules/`:
1. **`platform-alerts.yaml`**: App-level issues like `PlatformServiceUnavailable`, `PodCrashLooping`, and `HighHTTP5xxRate`.
2. **`infrastructure-alerts.yaml`**: Datastore and system health warnings like `MySQLUnavailable`, `RedisUnavailable`, `MQTTUnavailable`, and low node disk space.
3. **`robot-alerts.yaml`**: Domain-specific warnings like `RobotOffline`, `TelemetryIngestionStopped`, and AI inference errors.

---

## Grafana Dashboard Provisioning

Grafana dashboards are provisioned dynamically from JSON files inside `monitoring/dashboards/`:
- Dashboards are copied into the cluster as independent files.
- The `deploy-monitoring.sh` script applies these files to the cluster, where Grafana imports them via a watcher sidecar.

### Core Metrics Index

- **Robot Metrics**:
  - `robot_connected_status`: State of the physical robotic arm connection (1: Online, 0: Offline).
  - `robot_joint_commands_total`: Volume of joint commands processed.
- **Telemetry Metrics**:
  - `telemetry_ingestion_packets_total`: Count of webcam frames and sensor state updates received.
- **AI Metrics**:
  - `ai_inference_executions_total`: Rate of object detection inferences run.
  - `ai_inference_failures_total`: Inference failure rate.
