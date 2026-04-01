@echo off
chcp 65001 >nul
echo ========================================
echo   Restauración de datos del sistema
echo ========================================
echo.
echo Usa la base configurada en .env (SQL Server).
echo Restaurando roles, áreas, secretarías, usuarios,
echo planificación, proyectos y tareas según comandos...
echo.

cd /d "%~dp0backend"

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
