@echo off
chcp 65001 >nul
echo ========================================
echo   Sistema de Seguimiento de Proyectos
echo ========================================
echo.
echo Iniciando Backend (Django) en puerto 8001...
start /min "Backend - Django" cmd /k "cd /d "%~dp0backend" && python manage.py runserver 8001"
timeout /t 3 /nobreak >nul
echo Iniciando Frontend (Vite) en puerto 5173...
start /min "Frontend - Vite" cmd /k "cd /d "%~dp0frontend" && npm run dev"
echo.
echo ========================================
echo   IMPORTANTE - NO CERRAR las ventanas
echo ========================================
echo.
echo   Se abrieron 2 ventanas MINIMIZADAS en la barra de tareas.
echo   El Backend y Frontend deben seguir ejecutandose.
echo.
echo   - Si CIERRAS esas ventanas, el sistema deja de funcionar.
echo   - Si quieres ocultarlas, MINIMIZA (no cierres).
echo.
echo   Accede a: http://localhost:5173
echo ========================================
pause
