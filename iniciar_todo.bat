@echo off
title Iniciar Sistema de Proyectos
echo.
echo ========================================
echo   Iniciando Backend y Frontend
echo ========================================
echo.

cd /d "%~dp0"

echo [1/2] Iniciando Backend (Django) en puerto 8001...
start "Backend Django" cmd /k "cd /d %~dp0backend && python manage.py runserver 8001"

timeout /t 3 /nobreak > nul

echo [2/2] Iniciando Frontend (Vite) en puerto 5173...
start "Frontend Vite" cmd /k "cd /d %~dp0frontend && npm run dev"

echo.
echo ========================================
echo   Servidores iniciados
echo ========================================
echo   Backend:  http://localhost:8001
echo   Frontend: http://localhost:5173
echo ========================================
echo.
echo Se abrieron 2 ventanas. No las cierre.
echo.
pause
