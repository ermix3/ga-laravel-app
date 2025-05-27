#!/bin/bash
set -e

# Install cron if not already installed
if ! command -v cron &> /dev/null; then
    echo "Installing cron..."
    apt-get update && apt-get install -y cron && rm -rf /var/lib/apt/lists/*
fi

# Make backup script executable
chmod +x /db-backup.sh

# Set up cron job for automated backups at midnight
CRON_SCHEDULE=${BACKUP_SCHEDULE:-"0 0 * * *"}
echo "Setting up backup cron job with schedule: $CRON_SCHEDULE"

# Create cron job that runs the backup script
echo "$CRON_SCHEDULE root /db-backup.sh >> /backups/backup.log 2>&1" > /etc/cron.d/mysql-backup

# Give execution permissions to cron job file
chmod 0644 /etc/cron.d/mysql-backup

# Apply cron job
crontab /etc/cron.d/mysql-backup

# Start cron daemon in background
echo "Starting cron daemon..."
cron

# Create initial backup directory and log file
mkdir -p /backups
touch /backups/backup.log

echo "Backup system initialized successfully"
echo "Schedule: $CRON_SCHEDULE"
echo "Retention: ${BACKUP_RETENTION_DAYS:-7} days"
echo "Backup directory: /backups"

# Run the original MySQL entrypoint
echo "Starting MySQL server..."
exec docker-entrypoint.sh mysqld
