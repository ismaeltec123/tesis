@echo off
echo ========================================
echo   INICIANDO TODOS LOS SERVICIOS
echo ========================================
echo.

echo [1/3] Iniciando OCR Service (puerto 8002)...
start "OCR Service" cmd /k "cd docker && python app.py"
timeout /t 3 >nul

echo [2/3] Iniciando Backend (puerto 8001)...
start "Backend" cmd /k "cd google-calendar-backend && python simple_server.py"
timeout /t 3 >nul

echo [3/3] Iniciando Flutter (Chrome)...
start "Flutter" cmd /k "cd tesis && flutter run -d chrome"

echo.
echo ========================================
echo   TODOS LOS SERVICIOS INICIADOS
echo ========================================
echo.
echo OCR Service:  http://localhost:8002
echo Backend:      http://localhost:8001
echo Admin Panel:  cd admin-panel ^&^& npm run dev
echo.
pause
