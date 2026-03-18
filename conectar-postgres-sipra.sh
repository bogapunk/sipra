#!/bin/bash
# Conecta el contenedor postgres a la red sipra para que el backend pueda alcanzarlo.
# Ejecutar en el servidor: bash conectar-postgres-sipra.sh

RED=$(docker network ls --format '{{.Name}}' | grep -E 'sipra_default|sipra_sipra' | head -1)
if [ -z "$RED" ]; then
  echo "ERROR: No se encontró la red sipra. Levante primero: docker-compose -f docker-compose.produccion.yml up -d"
  exit 1
fi
echo "Conectando postgres a la red: $RED"
docker network connect "$RED" postgres 2>/dev/null && echo "OK: postgres conectado a $RED" || echo "postgres ya está en $RED o error al conectar"
echo "Reiniciando backend..."
docker-compose -f docker-compose.produccion.yml restart backend
echo "Listo. Ver logs: docker-compose -f docker-compose.produccion.yml logs -f backend"
