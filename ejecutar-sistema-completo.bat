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
set "SKIP_PROYECTOS_EJEMPLO=1"
python manage.py crear_datos_iniciales
python manage.py cargar_secretarias 2>nul

echo [3/5] Verificando usuarios en base de datos...
python manage.py shell -c "from users.models import Usuario; print('Usuarios activos:', Usuario.objects.filter(estado=True).count())"

echo [4/5] Iniciando backend en puerto 8001...
REM DEBUG=1 habilita CORS para desarrollo local
start "SIPRA Backend (PostgreSQL)" cmd /k "cd /d ""%~dp0backend"" && set ""DEBUG=1"" && set ""DB_PROVIDER=postgres"" && set ""POSTGRES_DB_HOST=localhost"" && set ""POSTGRES_DB_PORT=5432"" && set ""POSTGRES_DB_NAME=sipra"" && set ""POSTGRES_DB_USER=postgres"" && set ""POSTGRES_DB_PASSWORD=30153846"" && python manage.py runserver 8001"

echo Esperando 5 segundos para que el backend inicie...
timeout /t 5 /nobreak >nul

echo [5/5] Iniciando frontend en puerto 5173...
REM Sin VITE_API_BASE_URL: usa proxy de Vite (/api -> localhost:8001) para evitar CORS
start "SIPRA Frontend" cmd /k "cd /d ""%~dp0frontend"" && npm run dev"

echo.
echo ==============================================
echo   Sistema iniciado
echo ==============================================
echo Backend:  http://127.0.0.1:8001
echo Frontend: http://127.0.0.1:5173
echo ==============================================
echo.
echo CREDENCIALES DE ACCESO:
echo   - bogarin1983@gmail.com  /  Sipra2026
echo   - admin@admin.com       /  admin123
echo   - admin@sipra.local     /  AdminSipra2026!
echo.
echo NOTA: Se abrieron 2 ventanas nuevas (backend/frontend).
echo No las cierres mientras uses el sistema.
echo.
echo Si aparece "Token invalido o expirado": cierre sesion, abra en
echo ventana de incognito o borre localStorage del sitio, e inicie sesion de nuevo.
echo.
pause
