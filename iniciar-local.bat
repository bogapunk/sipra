@echo off
chcp 65001 >nul
title SIP-AIF - Inicio local (backend 8001 + frontend 5173)
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo ==============================================
echo   SIP-AIF - Inicio local automatico
echo ==============================================
echo   Backend  : http://127.0.0.1:8001
echo   Frontend : http://localhost:5173
echo   Base     : la definida en .env (Sipra-Test)
echo ==============================================
echo.

REM ------------------------------------------------------------------
REM  0) Verificar que Python y Node/npm esten disponibles en el PATH
REM ------------------------------------------------------------------
where python >nul 2>&1
if errorlevel 1 (
  echo ERROR: No se encontro "python" en el PATH.
  echo Instale Python o agreguelo al PATH y vuelva a intentar.
  pause
  exit /b 1
)
where npm >nul 2>&1
if errorlevel 1 (
  echo ERROR: No se encontro "npm" en el PATH.
  echo Instale Node.js o agreguelo al PATH y vuelva a intentar.
  pause
  exit /b 1
)

REM ------------------------------------------------------------------
REM  1) Liberar puertos 8001 y 5173 (instancias viejas que quedan colgadas)
REM     Esto evita que Vite salte a 5174 con el proxy mal configurado.
REM ------------------------------------------------------------------
echo [1/6] Liberando puertos 8001 y 5173 si estan ocupados...
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":8001 " ^| findstr LISTENING') do taskkill /F /PID %%P >nul 2>&1
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":5173 " ^| findstr LISTENING') do taskkill /F /PID %%P >nul 2>&1
echo     Puertos liberados.
echo.

REM ------------------------------------------------------------------
REM  2) Verificar conexion a la base de datos y aplicar migraciones
REM     (lee la configuracion del archivo .env en la raiz del proyecto)
REM ------------------------------------------------------------------
echo [2/6] Verificando base de datos y migraciones...
cd /d "%~dp0backend"
set "DEBUG=1"
python manage.py migrate --noinput
if errorlevel 1 (
  echo.
  echo ERROR: No se pudo conectar a la base de datos o aplicar migraciones.
  echo  - Revise el archivo .env: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_ODBC_DRIVER
  echo  - Verifique la VPN / firewall hacia el servidor SQL (puerto 1433)
  echo  - Confirme que el ODBC Driver 17 o 18 este instalado
  pause
  exit /b 1
)
echo     Base de datos OK.
echo.

REM ------------------------------------------------------------------
REM  3) Datos base (solo crea lo que falte; no pisa datos existentes)
REM ------------------------------------------------------------------
echo [3/6] Verificando datos base...
set "SKIP_PROYECTOS_EJEMPLO=1"
python manage.py crear_datos_iniciales >nul 2>&1
echo     Datos base verificados.
echo.

REM ------------------------------------------------------------------
REM  4) Dependencias del frontend (instala solo si faltan)
REM ------------------------------------------------------------------
echo [4/6] Verificando dependencias del frontend...
if not exist "%~dp0frontend\node_modules" (
  echo     Instalando dependencias por primera vez ^(puede tardar^)...
  cd /d "%~dp0frontend"
  call npm install
  if errorlevel 1 (
    echo ERROR: Fallo "npm install". Revise su conexion a internet.
    pause
    exit /b 1
  )
) else (
  echo     Dependencias ya instaladas.
)
echo.

REM ------------------------------------------------------------------
REM  5) Iniciar BACKEND en 8001 (ventana propia) y esperar a que responda
REM ------------------------------------------------------------------
echo [5/6] Iniciando backend en http://127.0.0.1:8001 ...
start "SIP-AIF Backend (8001)" cmd /k "cd /d ""%~dp0backend"" && set ""DEBUG=1"" && python manage.py runserver 8001"

echo     Esperando que el backend este listo...
set /a intentos=0
:wait_backend
set /a intentos+=1
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'http://127.0.0.1:8001/' -UseBasicParsing -TimeoutSec 3 | Out-Null; exit 0 } catch { if ($_.Exception.Response) { exit 0 } else { exit 1 } }" >nul 2>&1
if errorlevel 1 (
  if !intentos! geq 30 (
    echo     ADVERTENCIA: el backend tardo mas de lo esperado; continuo igual.
    goto backend_listo
  )
  timeout /t 2 /nobreak >nul
  goto wait_backend
)
:backend_listo
echo     Backend listo.
echo.

REM ------------------------------------------------------------------
REM  6) Iniciar FRONTEND en 5173 con el proxy apuntando al backend (8001)
REM     --strictPort fuerza el 5173 (no salta a 5174) para una URL estable.
REM ------------------------------------------------------------------
echo [6/6] Iniciando frontend en http://localhost:5173 ...
start "SIP-AIF Frontend (5173)" cmd /k "cd /d ""%~dp0frontend"" && set ""VITE_PROXY_TARGET=http://localhost:8001"" && npm run dev -- --port 5173 --strictPort"

echo     Esperando que el frontend compile...
timeout /t 8 /nobreak >nul

REM Abrir el navegador en la pantalla de login
start "" "http://localhost:5173/login"

echo.
echo ==============================================
echo   Sistema iniciado correctamente
echo ==============================================
echo   Backend  : http://127.0.0.1:8001
echo   Frontend : http://localhost:5173/login
echo ==============================================
echo.
echo NOTA: Se abrieron 2 ventanas (Backend y Frontend).
echo No las cierre mientras use el sistema.
echo Para detener todo, cierre esas dos ventanas.
echo.
pause
endlocal
