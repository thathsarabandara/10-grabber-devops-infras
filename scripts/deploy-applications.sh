#!/usr/bin/env bash
# deploy-applications.sh - Deploy microservices in dependency order and configure ingress/policies
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=============================================="
echo " Starting application microservices deployment..."
echo "=============================================="

# Helper function to deploy a service and wait for it
deploy_service() {
    local service_name=$1
    local dir_path="${REPO_ROOT}/kubernetes/applications/${service_name}"
    
    echo "Deploying ${service_name}..."
    kubectl apply -f "${dir_path}/configmap.yaml"
    kubectl apply -f "${dir_path}/service.yaml"
    kubectl apply -f "${dir_path}/deployment.yaml"
    
    echo "Waiting for ${service_name} deployment rollout..."
    kubectl rollout status deployment/"${service_name}" -n robot-platform --timeout=180s
    echo "${service_name} is successfully deployed."
    echo "----------------------------------------------"
}

# 1. API Gateway
deploy_service "api-gateway"

# 2. Auth Service
deploy_service "auth-service"

# 3. Robot Service
deploy_service "robot-service"

# 4. Telemetry Service
deploy_service "telemetry-service"

# 5. AI Service
deploy_service "ai-service"

# 6. Frontend
deploy_service "frontend"

# 7. Ingress resources
echo "Deploying NGINX Ingress rules..."
kubectl apply -f "${REPO_ROOT}/kubernetes/ingress/"

# 8. Security policies
echo "Deploying NetworkPolicies and Security configs..."
kubectl apply -f "${REPO_ROOT}/kubernetes/security/"

# 9. ServiceMonitors
echo "Deploying ServiceMonitors for monitoring integration..."
# Apply service monitors for all applications
for svc in auth-service robot-service telemetry-service ai-service api-gateway frontend; do
    if [[ -f "${REPO_ROOT}/kubernetes/applications/${svc}/service-monitor.yaml" ]]; then
        kubectl apply -f "${REPO_ROOT}/kubernetes/applications/${svc}/service-monitor.yaml"
    fi
done

echo "=============================================="
echo " Application deployment complete!"
echo "=============================================="
