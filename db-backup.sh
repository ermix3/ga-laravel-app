#!/bin/bash
set -e

# Backup configuration
MYSQL_HOST="localhost"
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"
LOG_FILE="${BACKUP_DIR}/backup.log"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a $LOG_FILE
}

# Check if required environment variables are set
if [[ -z "$MYSQL_USER" || -z "$MYSQL_PASSWORD" || -z "$MYSQL_DATABASE" ]]; then
    log_message "ERROR: Required environment variables (MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE) are not set."
    exit 1
fi

log_message "Starting database backup for database: $MYSQL_DATABASE, user: $MYSQL, host: $MYSQL_HOST"

# Wait for MySQL to be ready (in case this runs at startup)
until mysqladmin ping -h $MYSQL_HOST --silent; do
    log_message "Waiting for MySQL to be ready..."
    sleep 2
done

# Create database backup
if mysqldump -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $BACKUP_FILE 2>> $LOG_FILE; then
    # Compress the backup
    gzip $BACKUP_FILE

    # Get file size for logging
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)

    log_message "Backup completed successfully: ${BACKUP_FILE}.gz (${BACKUP_SIZE})"

    # Clean up old backups (keep only recent ones based on retention days)
    RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

    log_message "Cleaning up backups older than $RETENTION_DAYS days..."
    find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete 2>> $LOG_FILE

    log_message "Backup cleanup completed"

    # Log current backup count
    BACKUP_COUNT=$(find $BACKUP_DIR -name "backup_*.sql.gz" | wc -l)
    log_message "Total backups retained: $BACKUP_COUNT"

else
    log_message "ERROR: Backup failed!"
    exit 1
fi
