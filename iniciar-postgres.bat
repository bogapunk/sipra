@echo off
chcp 65001 >nul
echo ========================================
echo   SIPRA - Backend con PostgreSQL
echo ========================================
echo.
cd /d "%~dp0backend"
set DB_PROVIDER=postgres
if "%POSTGRES_DB_HOST%"=="" set POSTGRES_DB_HOST=localhost
if "%POSTGRES_DB_PORT%"=="" set POSTGRES_DB_PORT=5432
if "%POSTGRES_DB_NAME%"=="" set POSTGRES_DB_NAME=sipra
if "%POSTGRES_DB_USER%"=="" set POSTGRES_DB_USER=postgres
if "%POSTGRES_DB_PASSWORD%"=="" (
  set /p POSTGRES_DB_PASSWORD=Ingrese password PostgreSQL para %POSTGRES_DB_USER%: 
)
echo DB_PROVIDER=%DB_PROVIDER%
echo DB=%POSTGRES_DB_NAME% HOST=%POSTGRES_DB_HOST% PORT=%POSTGRES_DB_PORT% USER=%POSTGRES_DB_USER%
echo Iniciando servidor Django en http://127.0.0.1:8001
echo.
python manage.py runserver 8001
pause
