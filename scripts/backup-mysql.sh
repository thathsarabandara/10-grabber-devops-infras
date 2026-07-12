#!/usr/bin/env bash
# backup-mysql.sh - Perform database backups using mysqldump and kubectl exec
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKUP_DIR="${REPO_ROOT}/backups/mysql"

echo "=============================================="
echo " Starting MySQL Database Backup..."
echo "=============================================="

# 1. Create backups directory if missing
mkdir -p "$BACKUP_DIR"

# 2. Check if MySQL StatefulSet is running
if ! kubectl get statefulset/mysql -n robot-platform &>/dev/null; then
    echo "Error: MySQL statefulset does not exist in 'robot-platform' namespace." >&2
    exit 1
fi

# 3. Retrieve root password from Kubernetes Secrets
echo "Retrieving credentials from secret..."
MYSQL_ROOT_PASSWORD=$(kubectl get secret mysql-secrets -n robot-platform -o jsonpath='{.data.mysql-root-password}' | base64 --decode)

if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
    echo "Error: Failed to retrieve mysql root password from Kubernetes secret." >&2
    exit 1
fi

# 4. Generate timestamped file path
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/grabber_db_backup_${TIMESTAMP}.sql"

# 5. Run mysqldump
# Run without -t (no pseudo-TTY) to avoid escape codes corrupting the output stream
echo "Running mysqldump for databases: auth_db, robot_db, telemetry_db, ai_db..."
if kubectl exec statefulset/mysql -n robot-platform -- \
    mysqldump --single-transaction -uroot -p"${MYSQL_ROOT_PASSWORD}" \
    --databases auth_db robot_db telemetry_db ai_db > "$BACKUP_FILE"; then
    
    echo "Backup completed successfully!"
    echo "Backup File: ${BACKUP_FILE}"
    echo "File Size: $(du -sh "$BACKUP_FILE" | cut -f1)"
else
    echo "Error: Database backup execution failed." >&2
    rm -f "$BACKUP_FILE"
    exit 1
fi

echo "=============================================="
