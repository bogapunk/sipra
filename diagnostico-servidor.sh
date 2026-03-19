#!/bin/bash
# Diagnóstico SIP-AIF en servidor de producción
# Ejecutar en el servidor: ./diagnostico-servidor.sh

echo "=============================================="
echo "  SIP-AIF - Diagnóstico del servidor"
echo "=============================================="
echo ""

echo "1. Contenedores en ejecución:"
docker-compose -f docker-compose.produccion.yml ps 2>/dev/null || docker compose -f docker-compose.produccion.yml ps 2>/dev/null || echo "   Error al listar"
echo ""

echo "2. Puerto 8085 en uso:"
ss -tlnp | grep 8085 || netstat -tlnp 2>/dev/null | grep 8085 || echo "   No se encontró proceso en 8085"
echo ""

echo "3. Prueba local - Frontend (HTML):"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" http://localhost:8085/ 2>/dev/null || echo "   Error: no responde"
echo ""

echo "4. Prueba local - API:"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" http://localhost:8085/api/auth/login/ -X POST -H "Content-Type: application/json" -d '{}' 2>/dev/null || echo "   Error: no responde"
echo ""

echo "5. Últimas 30 líneas - Backend:"
docker-compose -f docker-compose.produccion.yml logs --tail=30 backend 2>/dev/null || docker compose -f docker-compose.produccion.yml logs --tail=30 backend 2>/dev/null || echo "   No se pudo obtener logs"
echo ""

echo "6. Últimas 15 líneas - Frontend:"
docker-compose -f docker-compose.produccion.yml logs --tail=15 frontend 2>/dev/null || docker compose -f docker-compose.produccion.yml logs --tail=15 frontend 2>/dev/null || echo "   No se pudo obtener logs"
echo ""

echo "=============================================="
echo "  Fin del diagnóstico"
echo "=============================================="
