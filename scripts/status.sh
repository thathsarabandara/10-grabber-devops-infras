#!/usr/bin/env pwd
#!/usr/bin/env bash
# status.sh - Display comprehensive cluster and infrastructure status
set -Eeuo pipefail

echo "=============================================="
echo " Gathering Cluster Status Details..."
echo "=============================================="

echo "--- 1. Node Status ---"
kubectl get nodes -o wide

echo ""
echo "--- 2. Namespaces ---"
kubectl get namespaces

echo ""
echo "--- 3. Pods (All namespaces) ---"
kubectl get pods -A -o wide

echo ""
echo "--- 4. Deployments (All namespaces) ---"
kubectl get deployments -A

echo ""
echo "--- 5. StatefulSets ---"
kubectl get statefulsets -A

echo ""
echo "--- 6. Services ---"
kubectl get services -A

echo ""
echo "--- 7. Ingress resources ---"
kubectl get ingress -A

echo ""
echo "--- 8. PVC Status ---"
kubectl get pvc -A

echo ""
echo "--- 9. Helm Releases ---"
helm list -A

echo ""
echo "--- 10. Cloudflared Logs (Last 10 lines) ---"
if kubectl get pods -n cloudflare -l app=cloudflared &>/dev/null; then
    kubectl logs -n cloudflare -l app=cloudflared --tail=10 || echo "No logs retrieved."
else
    echo "Cloudflared connector not running."
fi

echo "=============================================="
