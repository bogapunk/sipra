#!/bin/bash
# Despliegue SIP-AIF en servidor Linux (producción)
# Uso: ./deploy-produccion.sh
# Requiere: git, docker, docker-compose

set -e
cd "$(dirname "$0")"

echo "=============================================="
echo "  SIP-AIF - Despliegue en PRODUCCIÓN"
echo "=============================================="
echo ""

echo "[1/5] Actualizando código desde git..."
git pull

echo "[2/5] Deteniendo contenedores..."
docker-compose -f docker-compose.produccion.yml down || true

echo "[3/5] Construyendo imágenes (sin caché)..."
docker-compose -f docker-compose.produccion.yml build --no-cache

echo "[4/5] Iniciando servicios..."
docker-compose -f docker-compose.produccion.yml up -d

echo "[5/5] Esperando 15 segundos..."
sleep 15

echo ""
echo "=============================================="
echo "  SIP-AIF desplegado"
echo "=============================================="
echo ""
echo "Acceso: http://10.1.9.194:8085"
echo "BD: SQL Server 10.1.9.113 (Sipra)"
echo ""
echo "Comandos útiles:"
echo "  Logs backend:  docker-compose -f docker-compose.produccion.yml logs -f backend"
echo "  Logs frontend: docker-compose -f docker-compose.produccion.yml logs -f frontend"
echo "  Detener:       docker-compose -f docker-compose.produccion.yml down"
echo ""
