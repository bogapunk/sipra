@echo off
chcp 65001 >nul
title SIP-AIF - Diagnostico DB

echo ==============================================
echo   SIP-AIF - Diagnostico de conexion PostgreSQL
echo ==============================================
echo.

cd /d "%~dp0backend"

REM Forzamos variables esperadas para evitar residuos del entorno.
set "POSTGRES_DB_HOST=localhost"
set "POSTGRES_DB_PORT=5432"
set "POSTGRES_DB_NAME=sipra"
set "POSTGRES_DB_USER=postgres"
set "POSTGRES_DB_PASSWORD=30153846"

echo Ejecutando diagnostico...
python manage.py shell -c "from django.conf import settings; from django.db import connection; db=settings.DATABASES['default']; print('ENGINE   :', db.get('ENGINE')); print('HOST     :', repr(db.get('HOST'))); print('PORT     :', db.get('PORT')); print('DATABASE :', db.get('NAME')); print('USER     :', db.get('USER')); connection.ensure_connection(); print('CONEXION : OK')"

if errorlevel 1 (
  echo.
  echo RESULTADO: ERROR DE CONEXION.
  echo Revise PostgreSQL (servicio activo, credenciales y base sipra).
  pause
  exit /b 1
)

echo.
echo RESULTADO: Conexion correcta a PostgreSQL.
pause
