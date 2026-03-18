#!/bin/bash
# Conecta el contenedor postgres a la red sipra para que el backend pueda alcanzarlo.
# Ejecutar en el servidor: bash conectar-postgres-sipra.sh

cd "$(dirname "$0")"
COMPOSE="docker-compose -f docker-compose.produccion.yml"

RED=$(docker network ls --format '{{.Name}}' | grep -E 'sipra_default|sipra_sipra' | head -1)
if [ -z "$RED" ]; then
  echo "Levantando sipra para crear la red..."
  $COMPOSE up -d
  sleep 5
  RED=$(docker network ls --format '{{.Name}}' | grep -E 'sipra_default|sipra_sipra' | head -1)
fi
if [ -z "$RED" ]; then
  echo "ERROR: No se encontró la red sipra."
  exit 1
fi
echo "Conectando postgres a la red: $RED"
docker network connect "$RED" postgres 2>/dev/null && echo "OK: postgres conectado" || echo "postgres ya está en $RED"
echo "Levantando/recreando backend..."
$COMPOSE up -d --force-recreate backend
echo "Listo. Ver logs: $COMPOSE logs -f backend"
