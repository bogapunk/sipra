@echo off
chcp 65001 >nul
echo ========================================
echo   Restauración de datos del sistema
echo ========================================
echo.
echo Restaurando roles, áreas, secretarías, usuarios,
echo planificación 2026, proyectos y tareas...
echo.

cd /d "%~dp0backend"

set "POSTGRES_DB_HOST=localhost"
set "POSTGRES_DB_PORT=5432"
set "POSTGRES_DB_NAME=sipra"
set "POSTGRES_DB_USER=postgres"
set "POSTGRES_DB_PASSWORD=30153846"
set "SKIP_PROYECTOS_EJEMPLO=1"

python manage.py restaurar_sistema_completo

echo.
echo ===========================================
echo   Proceso finalizado
echo ========================================
echo.
echo Ejecute ejecutar-sistema-completo.bat para iniciar el sistema
echo o reinicie el backend si ya está en ejecución.
echo.
pause
