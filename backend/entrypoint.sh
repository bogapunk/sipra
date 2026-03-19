#!/bin/sh
set -e

echo "Ejecutando migraciones..."
for i in 1 2 3 4 5; do
  if python manage.py migrate --noinput; then
    break
  fi
  echo "Migrate falló (intento $i/5), reintentando en 10s..."
  sleep 10
done

echo "Iniciando servidor..."
exec gunicorn config.wsgi:application \
  --bind 0.0.0.0:8001 \
  --workers "${WEB_CONCURRENCY:-2}" \
  --threads "${GUNICORN_THREADS:-2}" \
  --timeout 90
