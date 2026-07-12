# Troubleshooting Guide

This document contains a diagnostic command sheet and solutions to common issues encountered when managing the Grabber Platform on k3s.

## Diagnostic Commands Reference

Use these commands to inspect the cluster state, review log history, and check the host service:

```bash
# 1. Inspect cluster nodes and namespace pods
kubectl get nodes
kubectl get pods -A
kubectl get pods -n robot-platform -o wide

# 2. Inspect individual pod events and specifications
kubectl describe pod <pod_name> -n robot-platform

# 3. Stream or view pod container logs
kubectl logs <pod_name> -n robot-platform
kubectl logs -f -l app=<app_label> -n robot-platform --tail=100

# 4. Check routing and networking resources
kubectl get ingress -A
kubectl get svc -n robot-platform

# 5. Check persistence storage volumes
kubectl get pvc -A
kubectl get pv

# 6. Check rollout histories and trigger restarts
kubectl rollout status deployment/<deployment_name> -n robot-platform
kubectl rollout restart deployment/<deployment_name> -n robot-platform

# 7. Check cluster event log (sorted by timestamp)
kubectl get events -A --sort-by=.metadata.creationTimestamp

# 8. List Helm chart releases
helm list -A

# 9. Verify k3s system daemon status and log outputs on the VM host
systemctl status k3s
journalctl -u k3s -n 100 -f
```

---

## Common Issues & Resolution

### 1. `ImagePullBackOff` / `ErrImagePull`
- **Cause**: Kubernetes cannot download the container image from GitHub Container Registry (GHCR).
- **Diagnosis**: Run `kubectl describe pod <pod_name> -n robot-platform` and look at the Event log.
- **Solution**:
  - Verify that the image name and tag in `config/platform.env` are correct.
  - Verify that the `ghcr-pull-secret` was successfully created. Run `kubectl get secret ghcr-pull-secret -n robot-platform`.
  - Re-run `make secrets` with correct `GHCR_USERNAME` and `GHCR_TOKEN` configurations in your root `.env` file.

### 2. `CrashLoopBackOff`
- **Cause**: The container started successfully but terminated or crashed shortly after.
- **Diagnosis**: Check the application log files: `kubectl logs <pod_name> -n robot-platform --previous`.
- **Solution**:
  - Most common cause is failing database or cache connectivity. Check if `mysql` and `redis` pods are running.
  - Verify environment variable URLs inside the config map or secrets.

### 3. `Pending` PVC
- **Cause**: Persistent Volume Claim is waiting for a volume provisioner.
- **Diagnosis**: Run `kubectl describe pvc <pvc_name> -n robot-platform`.
- **Solution**:
  - On k3s, ensure the `local-path` StorageClass is registered. Run `kubectl get storageclass`.
  - If missing, re-run `kubectl apply -f kubernetes/infrastructure/storage/local-path-storage.yaml`.

### 4. Failed Readiness Probe
- **Cause**: The container is running but does not respond to `/ready` (or Nginx port).
- **Diagnosis**: Run `kubectl describe pod <pod_name> -n robot-platform` and review events.
- **Solution**:
  - Check container logs to ensure the service successfully completed database migrations and started its web framework on port 8000.
  - Verify that the target port in the probe configuration matches the container port.

### 5. Cloudflare 502 Bad Gateway
- **Cause**: Cloudflare Tunnel daemon cannot connect to the NGINX Ingress controller, or NGINX Ingress is down.
- **Diagnosis**:
  - Verify the tunnel status in the Cloudflare Zero Trust panel.
  - Check tunnel logs: `kubectl logs -l app=cloudflared -n cloudflare`.
  - Ensure the NGINX controller service is online: `kubectl get svc -n ingress-nginx`.

### 6. NGINX 404 Not Found
- **Cause**: NGINX Ingress controller received the HTTP request but has no rule matching the Host header or Path.
- **Diagnosis**: Check ingress resources: `kubectl get ingress -A`.
- **Solution**:
  - Verify that the domain mapping in your Cloudflare Tunnel public hostname points exactly to the ingress controller (`http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80`).
  - Verify that the Ingress host matches the domain configuration in `config/domains.env`.

### 7. MySQL Connection Failures
- **Cause**: Microservices cannot authenticate with the MySQL database.
- **Solution**:
  - Check if the database initial initialization completed.
  - Verify credentials in `mysql-secrets`. To debug, decode the secret password: `kubectl get secret mysql-secrets -n robot-platform -o jsonpath='{.data.mysql-auth-password}' | base64 --decode`.
  - Re-run `make secrets` if credentials changed, then rollout restart the application: `make restart`.

### 8. MQTT WebSocket Connections failing
- **Cause**: WebSocket handshake failure when public clients try to reach `wss://mqtt.example.com`.
- **Solution**:
  - Verify NGINX Ingress annotations for WebSocket support are present.
  - Ensure the client is connecting over port 443 via HTTPS/TLS proxy.

### 9. Grafana / Prometheus Scraping Issues
- **Cause**: Grafana is unavailable, or Prometheus is not scraping microservice endpoints.
- **Solution**:
  - Ensure `prometheus-grafana` pod is running.
  - Check ServiceMonitors: `kubectl get servicemonitors -n robot-platform`.
  - Ensure labels on your ServiceMonitor resource match the release tag (`release: prometheus`).
