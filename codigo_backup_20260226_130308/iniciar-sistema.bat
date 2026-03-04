@echo off
chcp 65001 >nul
echo ========================================
echo   Sistema de Seguimiento de Proyectos
echo ========================================
echo.
echo Iniciando Backend (Django) en puerto 8001...
start "Backend - Django" cmd /k "cd /d "%~dp0backend" && python manage.py runserver 8001"
timeout /t 3 /nobreak >nul
echo Iniciando Frontend (Vite) en puerto 5173...
start "Frontend - Vite" cmd /k "cd /d "%~dp0frontend" && npm run dev"
echo.
echo ========================================
echo   Se abrieron 2 ventanas de consola.
echo   Mantenlas abiertas mientras uses el sistema.
echo.
echo   Accede a: http://localhost:5173
echo ========================================
pause
