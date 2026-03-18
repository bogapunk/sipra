@echo off
chcp 65001 >nul
title SIP-AIF - Detener producción

cd /d "%~dp0"

echo Deteniendo SIP-AIF en producción...
docker-compose -f docker-compose.yml -f docker-compose.produccion.yml down

echo.
echo Sistema detenido.
pause
