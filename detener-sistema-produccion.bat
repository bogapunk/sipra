@echo off
chcp 65001 >nul
title SIPRA - Detener producción

cd /d "%~dp0"

echo Deteniendo SIPRA en producción...
docker-compose -f docker-compose.yml -f docker-compose.produccion.yml down

echo.
echo Sistema detenido.
pause
