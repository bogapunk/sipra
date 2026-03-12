@echo off
setlocal

set "ROOT=C:\Users\hboga\OneDrive\Desktop\Agencia Inovacion-Economia del conocimientos\Proyectos 2026\Proyecto Sistema de Planificación de Proyectos\Sipra"
set "BACKUP=%ROOT%\backup_mejoras_intermedias_20260227"

if not exist "%BACKUP%" (
  echo No se encontro la carpeta de backup:
  echo %BACKUP%
  pause
  exit /b 1
)

echo Restaurando archivos previos a las mejoras intermedias...

copy /Y "%BACKUP%\frontend\src\views\DashboardView.vue" "%ROOT%\frontend\src\views\DashboardView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\ProyectosView.vue" "%ROOT%\frontend\src\views\ProyectosView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\TareasView.vue" "%ROOT%\frontend\src\views\TareasView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\AvancesPorAreaView.vue" "%ROOT%\frontend\src\views\AvancesPorAreaView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\AvancesPorSecretariaView.vue" "%ROOT%\frontend\src\views\AvancesPorSecretariaView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\CalendarioView.vue" "%ROOT%\frontend\src\views\CalendarioView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\AreasView.vue" "%ROOT%\frontend\src\views\AreasView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\SecretariasView.vue" "%ROOT%\frontend\src\views\SecretariasView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\UsuariosView.vue" "%ROOT%\frontend\src\views\UsuariosView.vue" >nul
copy /Y "%BACKUP%\frontend\src\views\RolesView.vue" "%ROOT%\frontend\src\views\RolesView.vue" >nul
copy /Y "%BACKUP%\frontend\src\assets\styles.css" "%ROOT%\frontend\src\assets\styles.css" >nul

echo.
echo Archivos restaurados correctamente.
echo Si tiene el frontend abierto, vuelva a compilar o reiniciar el sistema para ver los cambios.
pause
