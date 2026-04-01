@echo off
chcp 65001 >nul
title SIP-AIF - Diagnostico SQL Server

echo ==============================================
echo   SIP-AIF - Diagnostico de conexion SQL Server
echo ==============================================
echo.
echo Usa la configuracion del archivo .env en la raiz del proyecto (DB_HOST, DB_NAME, etc.)
echo.

cd /d "%~dp0backend"

echo Ejecutando diagnostico...
python manage.py shell -c "from django.conf import settings; from django.db import connection; db=settings.DATABASES['default']; print('ENGINE   :', db.get('ENGINE')); print('HOST     :', repr(db.get('HOST'))); print('PORT     :', db.get('PORT')); print('DATABASE :', db.get('NAME')); print('USER     :', db.get('USER')); connection.ensure_connection(); print('CONEXION : OK')"

if errorlevel 1 (
  echo.
  echo RESULTADO: ERROR DE CONEXION.
  echo Revise .env (DB_*), ODBC Driver 17/18, VPN/red hacia el servidor SQL y puerto 1433.
  pause
  exit /b 1
)

echo.
echo RESULTADO: Conexion correcta a SQL Server.
pause
