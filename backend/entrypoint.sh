#!/bin/sh
set -e

echo "Ejecutando migraciones..."
python manage.py migrate --noinput

echo "Iniciando servidor..."
exec gunicorn config.wsgi:application \
  --bind 0.0.0.0:8001 \
  --workers "${WEB_CONCURRENCY:-2}" \
  --threads "${GUNICORN_THREADS:-2}" \
  --timeout 120
