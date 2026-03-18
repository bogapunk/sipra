#!/bin/bash
# Script para desplegar SIP-AIF en un servidor (ej. VPS)
# Uso: ./deploy-demo.sh

set -e

echo "=== Despliegue SIP-AIF Demo ==="

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
fi

# Crear .env si no existe
if [ ! -f .env ]; then
    echo "Creando .env..."
    SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))" 2>/dev/null || openssl rand -base64 32)
    cat > .env << EOF
SECRET_KEY=$SECRET
DEBUG=0
ALLOWED_HOSTS=*
EOF
    echo "  .env creado con SECRET_KEY generada."
else
    echo "  .env ya existe."
fi

# Construir y levantar
echo "Construyendo y levantando contenedores..."
docker compose up -d --build

# Esperar a que el backend esté listo
echo "Esperando al backend..."
sleep 15

# Crear datos iniciales (si no existen)
echo "Creando datos iniciales..."
docker compose exec -T backend python manage.py crear_datos_iniciales || true
docker compose exec -T backend python manage.py resetear_password_admin || true

echo ""
echo "=== ¡Listo! ==="
IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
echo "Accede a: http://$IP"
echo "Credenciales: admin@admin.com / admin123"
echo ""
