@echo off
cd /d "%~dp0backend"
echo Iniciando servidor Django en http://127.0.0.1:8001
echo.
python manage.py runserver 8001
pause
