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

python manage.py restaurar_sistema_completo

echo.
echo ========================================
echo   Proceso finalizado
echo ========================================
echo.
echo Ejecute iniciar-sistema.bat para iniciar el sistema
echo o reinicie el backend si ya está en ejecución.
echo.
pause
