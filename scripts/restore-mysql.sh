#!/usr/bin/env bash
# restore-mysql.sh - Restore database from an SQL backup file
set -Eeuo pipefail

echo "=============================================="
echo " Starting Database Restore Sequence..."
echo "=============================================="

# 1. Require a backup path argument
if [[ $# -ne 1 ]]; then
    echo "Error: Missing backup file path." >&2
    echo "Usage: $0 <path_to_backup_file.sql>" >&2
    exit 1
fi

BACKUP_FILE="$1"

# 2. Validate backup file existence and content
if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: Backup file '${BACKUP_FILE}' does not exist." >&2
    exit 1
fi

if [[ ! -s "$BACKUP_FILE" ]]; then
    echo "Error: Backup file '${BACKUP_FILE}' is empty." >&2
    exit 1
fi

# Basic check to ensure it looks like a MySQL dump file
if ! grep -q "MySQL dump" "$BACKUP_FILE" && ! grep -q "CREATE DATABASE" "$BACKUP_FILE"; then
    echo "Warning: File does not seem to contain a standard MySQL dump structure." >&2
    read -r -p "Do you still want to proceed with restore? [y/N] " proceed_warn
    if [[ ! "$proceed_warn" =~ ^[yY]([eE][sS])?$ ]]; then
        echo "Restore cancelled."
        exit 0
    fi
fi

# 3. Retrieve root password from Kubernetes Secrets
MYSQL_ROOT_PASSWORD=$(kubectl get secret mysql-secrets -n robot-platform -o jsonpath='{.data.mysql-root-password}' | base64 --decode)
if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
    echo "Error: Failed to retrieve mysql root password from Kubernetes secret." >&2
    exit 1
fi

# 4. Require explicit confirmation
echo ""
echo "========================== WARNING =========================="
echo " Restoring this backup will OVERWRITE any existing data in:"
echo "   - auth_db"
echo "   - robot_db"
echo "   - telemetry_db"
echo "   - ai_db"
echo "============================================================="
read -r -p "Are you absolutely sure you want to perform this restore? (type 'yes' to confirm): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Restore sequence aborted by user."
    exit 0
fi

# 5. Restore database
echo "Restoring database from ${BACKUP_FILE}..."
# Pass -i without -t to pipe database data properly
if kubectl exec -i statefulset/mysql -n robot-platform -- \
    mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" < "$BACKUP_FILE"; then
    
    echo "Database restoration completed successfully!"
else
    echo "Error: Database restoration failed." >&2
    exit 1
fi

echo "=============================================="
