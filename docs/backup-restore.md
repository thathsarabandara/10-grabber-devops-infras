# Backup and Restore Procedures

This document describes how to execute automated backups and restore operations for the MySQL databases on the Grabber Platform.

## Database Backup

MySQL is deployed inside Kubernetes as a StatefulSet (`mysql-0`). The backup script [backup-mysql.sh](file:///home/thathsara/Desktop/Thathsara/Project/Grabber/11-grabber-devops-infras/scripts/backup-mysql.sh) dumps all 4 platform databases using `mysqldump` streamed directly from the container to the local VM filesystem.

### 1. Manual Backup Execution
Run the following make command to perform a backup:
```bash
make backup
```
Or execute the script directly:
```bash
./scripts/backup-mysql.sh
```

### 2. Backup Location & Naming
Backup files are written to:
`backups/mysql/grabber_db_backup_YYYYMMDD_HHMMSS.sql`

This folder is ignored by Git, meaning your local SQL dumps will never be accidentally committed to the source control repository.

---

## Database Restoration

Restoring a database will overwrite current table states and users. The restoration script [restore-mysql.sh](file:///home/thathsara/Desktop/Thathsara/Project/Grabber/11-grabber-devops-infras/scripts/restore-mysql.sh) requires a backup file argument and prompts the user for explicit confirmation before executing.

### 1. Restore Execution
Pass the path of the target backup file to the Makefile target:
```bash
make restore BACKUP_FILE=/path/to/backups/mysql/grabber_db_backup_20260712_020000.sql
```
Or execute the script:
```bash
./scripts/restore-mysql.sh /path/to/backups/mysql/grabber_db_backup_20260712_020000.sql
```

### 2. Safeguards and Validation
- **Path Verification**: The script checks that the file exists and is non-empty.
- **SQL Structure Validation**: The script checks if the file has standard MySQL header indicators (`MySQL dump` or `CREATE DATABASE`).
- **Interactive Prompt**: The script prints a warning checklist and prompts you to type `yes` before initiating the restore query:
  ```text
  ========================== WARNING ==========================
   Restoring this backup will OVERWRITE any existing data in:
     - auth_db
     - robot_db
     - telemetry_db
     - ai_db
  =============================================================
  Are you absolutely sure you want to perform this restore? (type 'yes' to confirm):
  ```

### 3. Post-Restore Verification
After a successful restore, restart the microservice pods to clear caching issues and establish active DB connections:
```bash
make restart
```
Check microservice logs to verify that connections have resumed cleanly.
