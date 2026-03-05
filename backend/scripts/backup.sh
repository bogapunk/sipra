#!/bin/bash
# Script de backup para PostgreSQL (ejemplo Linux)
# Configurar BACKUP_SCRIPT_PATH en settings o variable de entorno.

set -e
BACKUP_DIR="${BACKUP_DIR:-/opt/backups}"
PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5432}"
PGDATABASE="${PGDATABASE:-sipra}"
PGUSER="${PGUSER:-postgres}"
PGPASSWORD="${PGPASSWORD:-}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"
PGPASSWORD="$PGPASSWORD" pg_dump \
  -h "$PGHOST" \
  -p "$PGPORT" \
  -U "$PGUSER" \
  -d "$PGDATABASE" \
  -f "$BACKUP_DIR/backup_${TIMESTAMP}.sql"
echo "Backup creado: $BACKUP_DIR/backup_${TIMESTAMP}.sql"
