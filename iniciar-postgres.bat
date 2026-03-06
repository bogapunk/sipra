@echo off
chcp 65001 >nul
echo ========================================
echo   SIPRA - Backend con PostgreSQL
echo ========================================
echo.
cd /d "%~dp0backend"
set "DB_PROVIDER=postgres"
set "POSTGRES_DB_HOST=localhost"
set "POSTGRES_DB_PORT=5432"
set "POSTGRES_DB_NAME=sipra"
set "POSTGRES_DB_USER=postgres"
set "POSTGRES_DB_PASSWORD=30153846"
echo DB_PROVIDER=%DB_PROVIDER%
echo DB=%POSTGRES_DB_NAME% HOST=%POSTGRES_DB_HOST% PORT=%POSTGRES_DB_PORT% USER=%POSTGRES_DB_USER%
echo Iniciando servidor Django en http://127.0.0.1:8001
echo.
python manage.py runserver 8001
pause
