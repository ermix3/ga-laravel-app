#!/bin/bash
set -e

# Install cron if not already installed
if ! command -v crond &> /dev/null; then
    echo "Installing crond..."
    if command -v microdnf &> /dev/null; then
        echo "Using microdnf to install cronie"
        microdnf install -y cronie && microdnf clean all
    elif command -v dnf &> /dev/null; then
        echo "Using dnf to install cronie"
        dnf install -y cronie && dnf clean all
    elif command -v yum &> /dev/null; then
        echo "Using yum to install cronie"
        yum install -y cronie && yum clean all
    else
        echo "ERROR: No supported package manager found"
        exit 1
    fi
fi

# Create backup directory and log file
mkdir -p /backups
touch /backups/backup.log

# Export environment variables for cron
printenv | grep -E 'MYSQL_|BACKUP_RETENTION_DAYS' > /etc/cron.env

# Make sure variables are exported properly
echo "export $(cat /etc/cron.env | xargs)" > /etc/cron.env

# Set up cron job for automated backups at midnight
CRON_SCHEDULE=${BACKUP_SCHEDULE:-"0 0 * * *"}
echo "Setting up backup cron job with schedule: $CRON_SCHEDULE"

# Create cron job that runs the backup script with sourced environment
echo "$CRON_SCHEDULE root . /etc/cron.env && /bin/bash /db-backup.sh >> /backups/backup.log 2>&1" > /etc/cron.d/mysql-backup

# Give execution permissions to cron job file
chmod 0644 /etc/cron.d/mysql-backup

# Start cron daemon in background
echo "Starting cron daemon..."
crond

echo "Backup system initialized successfully"
echo "Schedule: $CRON_SCHEDULE"
echo "Retention: ${BACKUP_RETENTION_DAYS:-7} days"
echo "Backup directory: /backups"

# Start MySQL server
echo "Starting MySQL server..."
exec docker-entrypoint.sh mysqld
