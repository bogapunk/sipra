@echo off
chcp 65001 >nul
title SIPRA - Ejecutar sistema completo (PostgreSQL)

echo ==============================================
echo   SIPRA - Ejecucion completa con PostgreSQL
echo ==============================================
echo.
echo Tip: si quieres validar primero la DB, ejecuta: diagnostico-db.bat
echo.

cd /d "%~dp0"

REM ====== Variables fijas de PostgreSQL ======
set "DB_PROVIDER=postgres"
set "POSTGRES_DB_HOST=localhost"
set "POSTGRES_DB_PORT=5432"
set "POSTGRES_DB_NAME=sipra"
set "POSTGRES_DB_USER=postgres"
set "POSTGRES_DB_PASSWORD=30153846"

echo [1/5] Verificando conexion y migraciones en PostgreSQL...
cd /d "%~dp0backend"
python manage.py migrate --noinput
if errorlevel 1 (
  echo.
  echo ERROR: No se pudo conectar/aplicar migraciones en PostgreSQL.
  echo Revisar servicio PostgreSQL, usuario, password y base sipra.
  pause
  exit /b 1
)

echo [2/5] Cargando datos base (si faltan)...
python manage.py crear_datos_iniciales
python manage.py cargar_secretarias 2>nul

echo [3/5] Verificando usuario lolo@gmail.com en PostgreSQL...
python manage.py shell -c "from users.models import Usuario; print('Usuarios totales:', Usuario.objects.count()); print('lolo@gmail.com existe:', Usuario.objects.filter(email='lolo@gmail.com').exists())"

echo [4/5] Iniciando backend en puerto 8001...
start "SIPRA Backend (PostgreSQL)" cmd /k "cd /d ""%~dp0backend"" && set ""DB_PROVIDER=postgres"" && set ""POSTGRES_DB_HOST=localhost"" && set ""POSTGRES_DB_PORT=5432"" && set ""POSTGRES_DB_NAME=sipra"" && set ""POSTGRES_DB_USER=postgres"" && set ""POSTGRES_DB_PASSWORD=30153846"" && python manage.py runserver 8001"

timeout /t 3 /nobreak >nul

echo [5/5] Iniciando frontend en puerto 5173...
start "SIPRA Frontend" cmd /k "cd /d ""%~dp0frontend"" && set VITE_API_BASE_URL=http://127.0.0.1:8001/api && npm run dev"

echo.
echo ==============================================
echo   Sistema iniciado
echo ==============================================
echo Backend:  http://127.0.0.1:8001
echo Frontend: http://127.0.0.1:5173
echo ==============================================
echo.
echo NOTA: Se abrieron 2 ventanas nuevas (backend/frontend).
echo No las cierres mientras uses el sistema.
echo.
pause
