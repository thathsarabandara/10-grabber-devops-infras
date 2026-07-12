#!/usr/bin/env bash
# logs.sh - Retrieve container log output streams
set -Eeuo pipefail

if [[ $# -lt 1 ]]; then
    echo "Error: Missing target service name." >&2
    echo "Usage: $0 <service_name> [options]" >&2
    echo "Example services: api-gateway, auth-service, robot-service, telemetry-service, ai-service, frontend, mysql, redis, mqtt, cloudflared" >&2
    exit 1
fi

SERVICE_NAME="$1"
shift # Shift arguments to pass remaining flags to kubectl (e.g. -f, --tail)

NAMESPACE="robot-platform"
SELECTOR=""

# Determine namespace and label mappings
case "$SERVICE_NAME" in
    api-gateway|auth-service|robot-service|telemetry-service|ai-service|frontend)
        NAMESPACE="robot-platform"
        SELECTOR="app=${SERVICE_NAME}"
        ;;
    mysql)
        NAMESPACE="robot-platform"
        SELECTOR="app=mysql"
        ;;
    redis)
        NAMESPACE="robot-platform"
        SELECTOR="app=redis"
        ;;
    mqtt)
        NAMESPACE="robot-platform"
        SELECTOR="app=mqtt"
        ;;
    cloudflared)
        NAMESPACE="cloudflare"
        SELECTOR="app=cloudflared"
        ;;
    *)
        echo "Error: Unknown service name '${SERVICE_NAME}'." >&2
        exit 1
        ;;
esac

echo "Streaming logs for ${SERVICE_NAME} in namespace ${NAMESPACE}..."
kubectl logs -n "$NAMESPACE" -l "$SELECTOR" --tail=100 "$@"
