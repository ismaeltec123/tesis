@echo off
echo ========================================
echo   ML Rescheduling Service - START
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] Checking Python...
python --version
if errorlevel 1 (
    echo ERROR: Python not found!
    pause
    exit /b 1
)

echo.
echo [2/3] Installing dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install dependencies!
    pause
    exit /b 1
)

echo.
echo [3/3] Starting ML Service...
echo.
echo Service will be available at: http://localhost:5000
echo.
echo Press Ctrl+C to stop the service
echo.

python app.py

pause
