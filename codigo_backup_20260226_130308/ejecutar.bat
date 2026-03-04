@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo === BACKEND ===
cd backend
python manage.py migrate
python manage.py crear_datos_iniciales
start /B python manage.py runserver
cd ..

echo === FRONTEND ===
cd frontend
call npm install
start /B npm run dev
cd ..

echo.
echo Backend: http://localhost:8000
echo Frontend: http://localhost:5173
echo.
pause
