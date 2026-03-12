@echo off
setlocal

set "ROOT=C:\Users\hboga\OneDrive\Desktop\Agencia Inovacion-Economia del conocimientos\Proyectos 2026\Proyecto Sistema de Planificación de Proyectos\Sipra"
set "BACKUP=%ROOT%\backup_dashboard_echarts_20260227"

if not exist "%BACKUP%" (
  echo No se encontro la carpeta de backup:
  echo %BACKUP%
  pause
  exit /b 1
)

echo Restaurando archivos originales del dashboard...

copy /Y "%BACKUP%\backend\dashboards\views.py" "%ROOT%\backend\dashboards\views.py" >nul
copy /Y "%BACKUP%\backend\projects\urls.py" "%ROOT%\backend\projects\urls.py" >nul
copy /Y "%BACKUP%\frontend\package.json" "%ROOT%\frontend\package.json" >nul
copy /Y "%BACKUP%\frontend\package-lock.json" "%ROOT%\frontend\package-lock.json" >nul
copy /Y "%BACKUP%\frontend\src\services\dashboard.ts" "%ROOT%\frontend\src\services\dashboard.ts" >nul
copy /Y "%BACKUP%\frontend\src\services\api.ts" "%ROOT%\frontend\src\services\api.ts" >nul
copy /Y "%BACKUP%\frontend\src\views\DashboardView.vue" "%ROOT%\frontend\src\views\DashboardView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\ProyectosView.vue" "%ROOT%\frontend\src\views\ProyectosView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\TareasView.vue" "%ROOT%\frontend\src\views\TareasView.vue" >nul

echo Restaurando dependencias del frontend...
pushd "%ROOT%\frontend"
call npm install
if errorlevel 1 (
  echo.
  echo Se restauraron los archivos, pero npm install fallo.
  popd
  pause
  exit /b 1
)
popd

echo.
echo Restauracion completada. El sistema volvio al estado anterior del dashboard.
pause
