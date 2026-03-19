@echo off
chcp 65001 >nul
title SIP-AIF - Producción (10.1.9.194:8085)

echo ==============================================
echo   SIP-AIF - Entorno de PRODUCCIÓN
echo ==============================================
echo.
echo Servidor: 10.1.9.194
echo Puerto:   8085
echo Acceso:   http://10.1.9.194:8085
echo.

cd /d "%~dp0"

REM ====== Parámetros de producción ======
set "IP_APLICACION=10.1.9.194"
set "PUERTO_APLICACION=8085"
REM BD: SQL Server 10.1.9.113 (Sipra) - configurado en docker-compose.produccion.yml

REM ====== Variables para Docker ======
set "DEBUG=0"
set "SECRET_KEY=sipra-produccion-clave-segura-cambiar"
set "ALLOWED_HOSTS=10.1.9.194,localhost,127.0.0.1"
set "CORS_ALLOWED_ORIGINS=http://10.1.9.194:8085"
set "CSRF_TRUSTED_ORIGINS=http://10.1.9.194:8085"
set "WEB_CONCURRENCY=3"
set "GUNICORN_THREADS=2"

echo [1/4] Verificando Docker...
docker --version >nul 2>&1
if errorlevel 1 (
  echo ERROR: Docker no está instalado o no está en el PATH.
  pause
  exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
  echo ERROR: docker-compose no está disponible.
  pause
  exit /b 1
)

echo [2/4] Construyendo imágenes (sin caché para aplicar cambios)...
docker-compose -f docker-compose.produccion.yml build --no-cache

echo [3/4] Iniciando servicios de producción...
docker-compose -f docker-compose.produccion.yml up -d

if errorlevel 1 (
  echo.
  echo ERROR: No se pudo iniciar el sistema.
  echo Verifique que Docker esté corriendo y que el puerto %PUERTO_APLICACION% esté libre.
  echo y que el puerto %PUERTO_APLICACION% esté libre.
  pause
  exit /b 1
)

echo [4/4] Esperando que los servicios estén listos...
timeout /t 10 /nobreak >nul

echo.
echo ==============================================
echo   SIP-AIF en producción - INICIADO
echo ==============================================
echo.
echo Acceso a la aplicación: http://%IP_APLICACION%:%PUERTO_APLICACION%
echo.
echo Base de datos: SQL Server 10.1.9.113 (Sipra)
echo.
echo Comandos útiles:
echo   Ver logs:     docker-compose -f docker-compose.produccion.yml logs -f
echo   Detener:      docker-compose -f docker-compose.produccion.yml down
echo.
pause
