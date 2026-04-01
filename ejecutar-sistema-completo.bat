@echo off
chcp 65001 >nul
title SIP-AIF - Ejecutar sistema completo (SQL Server)

echo ==============================================
echo   SIP-AIF - Ejecucion completa (SQL Server)
echo ==============================================
echo.
echo La base se configura en el archivo .env (raiz del proyecto): DB_HOST, DB_NAME, etc.
echo Si migrate falla con "timeout" hacia el servidor SQL: conectese a la VPN de la oficina
echo o verifique firewall / que SQL Server acepte conexiones remotas en el puerto 1433.
echo.
echo Tip: diagnostico-db.bat (si existe) o: python backend\check_db_produccion.py
echo.

cd /d "%~dp0"

echo [1/5] Verificando conexion y migraciones (lee .env en la raiz del proyecto)...
cd /d "%~dp0backend"
REM No usar ERRORLEVEL con expansion diferida: !ERRORLEVEL! puede quedar vacio y fallar siempre.
python manage.py migrate --noinput && goto :migrate_ok
echo.
echo ERROR: No se pudo conectar a SQL Server o aplicar migraciones.
echo - Revise .env: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_ODBC_DRIVER
echo - Desde esta PC debe poder alcanzar el servidor (ej. Test-NetConnection DB_HOST -Port 1433)
echo - ODBC Driver 17 u 18 instalado en Windows
pause
exit /b 1
:migrate_ok

echo [2/5] Cargando datos base (si faltan)...
set "SKIP_PROYECTOS_EJEMPLO=1"
python manage.py crear_datos_iniciales
python manage.py cargar_secretarias 2>nul

echo [3/5] Verificando usuarios en base de datos...
python manage.py shell -c "from users.models import Usuario; print('Usuarios activos:', Usuario.objects.filter(estado=True).count())"

echo [4/5] Iniciando backend en puerto 8001...
REM Usa variables del .env; DEBUG=1 para desarrollo local
start "SIP-AIF Backend (SQL Server)" cmd /k "cd /d ""%~dp0backend"" && set ""DEBUG=1"" && python manage.py runserver 8001"

echo Esperando 5 segundos para que el backend inicie...
timeout /t 5 /nobreak >nul

echo [5/5] Iniciando frontend en puerto 5173...
start "SIP-AIF Frontend" cmd /k "cd /d ""%~dp0frontend"" && npm run dev"

echo.
echo ==============================================
echo   Sistema iniciado
echo ==============================================
echo Backend:  http://127.0.0.1:8001
echo Frontend: http://127.0.0.1:5173
echo ==============================================
echo.
echo CREDENCIALES: ver .env (BOOTSTRAP_* o usuarios creados en la BD)
echo.
echo NOTA: Se abrieron 2 ventanas (backend/frontend). No las cierre mientras use el sistema.
echo.
pause
