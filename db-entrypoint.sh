#!/bin/bash
set -e

# Install cron if not already installed
if ! command -v cron &> /dev/null; then
    echo "Installing cron..."
    if command -v microdnf &> /dev/null; then
        # For Oracle Linux 8 (newer MySQL images)
        microdnf install -y cronie && microdnf clean all
    elif command -v dnf &> /dev/null; then
        dnf install -y cronie && dnf clean all
    elif command -v yum &> /dev/null; then
        # For older Oracle Linux versions
        yum install -y cronie && yum clean all
    else
        echo "ERROR: No supported package manager found"
        exit 1
    fi
fi

# Create backup directory and log file
mkdir -p /backups
touch /backups/backup.log

# Set up cron job for automated backups at midnight
CRON_SCHEDULE=${BACKUP_SCHEDULE:-"0 0 * * *"}
echo "Setting up backup cron job with schedule: $CRON_SCHEDULE"

# Create cron job that runs the backup script
echo "$CRON_SCHEDULE root /bin/bash /db-backup.sh >> /backups/backup.log 2>&1" > /etc/cron.d/mysql-backup

# Give execution permissions to cron job file
chmod 0644 /etc/cron.d/mysql-backup

# Apply cron job
crontab /etc/cron.d/mysql-backup

# Start cron daemon in background
echo "Starting cron daemon..."
cron

echo "Backup system initialized successfully"
echo "Schedule: $CRON_SCHEDULE"
echo "Retention: ${BACKUP_RETENTION_DAYS:-7} days"
echo "Backup directory: /backups"

# Start MySQL server
echo "Starting MySQL server..."
exec docker-entrypoint.sh mysqld
