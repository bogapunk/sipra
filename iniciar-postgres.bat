@echo off
chcp 65001 >nul
echo ========================================
echo   SIPRA - Backend con PostgreSQL
echo ========================================
echo.
cd /d "%~dp0backend"
set DB_PROVIDER=postgres
echo DB_PROVIDER=%DB_PROVIDER%
echo Iniciando servidor Django en http://127.0.0.1:8001
echo.
python manage.py runserver 8001
pause
