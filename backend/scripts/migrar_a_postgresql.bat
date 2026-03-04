@echo off
chcp 65001 >nul
echo ========================================
echo   Migración SQLite -^> PostgreSQL
echo ========================================
echo.
echo IMPORTANTE: Ejecute este script SIN tener DATABASE_URL en .env
echo             (o renombre .env temporalmente) para exportar desde SQLite.
echo.

cd /d "%~dp0.."

echo [1/4] Exportando datos desde SQLite...
python manage.py dumpdata --natural-foreign --natural-primary -e contenttypes -e auth.Permission --indent 2 -o datos_migracion.json 2>nul
if errorlevel 1 (
    echo ERROR: No se pudo exportar. ¿Está usando SQLite actualmente?
    echo        Asegúrese de NO tener DATABASE_URL en .env
    pause
    exit /b 1
)
echo OK: datos_migracion.json creado
echo.

echo [2/4] Configure DATABASE_URL para PostgreSQL.
echo       Agregue a .env: DATABASE_URL=postgres://sipra:password@localhost:5432/sipra
echo       O ejecute: set DATABASE_URL=postgres://sipra:password@localhost:5432/sipra
echo.
set /p CONTINUAR="¿DATABASE_URL ya está configurada en .env o en el sistema? (s/n): "
if /i not "%CONTINUAR%"=="s" (
    echo Cree/edite .env con DATABASE_URL y vuelva a ejecutar este script.
    pause
    exit /b 0
)

echo [3/4] Creando tablas en PostgreSQL...
python manage.py migrate
if errorlevel 1 (
    echo ERROR: Falló migrate. Verifique que PostgreSQL esté corriendo y DATABASE_URL sea correcta.
    pause
    exit /b 1
)
echo OK
echo.

echo [4/4] Cargando datos...
python manage.py loaddata datos_migracion.json
if errorlevel 1 (
    echo ERROR: Falló loaddata.
    pause
    exit /b 1
)
echo OK
echo.

echo ========================================
echo   Migración completada
echo ========================================
echo   Puede eliminar datos_migracion.json si ya no lo necesita.
echo   Mantenga DATABASE_URL para usar PostgreSQL.
pause
