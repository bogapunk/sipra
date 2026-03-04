#!/bin/bash
# Script de backup para SQLite (ejemplo para Linux)
# Configurar BACKUP_SCRIPT_PATH en settings o variable de entorno
# para usar este script en lugar del backup interno de Django.

set -e
BACKUP_DIR="${BACKUP_DIR:-/opt/backups}"
DB_PATH="${DB_PATH:-/app/backend/db.sqlite3}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"
cp "$DB_PATH" "$BACKUP_DIR/backup_${TIMESTAMP}.sqlite3"
echo "Backup creado: $BACKUP_DIR/backup_${TIMESTAMP}.sqlite3"
