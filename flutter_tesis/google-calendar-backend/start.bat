@echo off
echo Iniciando Google Calendar Integration API...
echo.

REM Verificar que Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python no está instalado o no está en el PATH
    pause
    exit /b 1
)

REM Verificar que las dependencias están instaladas
python -c "import fastapi" >nul 2>&1
if errorlevel 1 (
    echo Instalando dependencias...
    pip install -r requirements.txt
)

REM Verificar archivos de configuración
if not exist "config\credentials.json" (
    echo.
    echo ¡IMPORTANTE! No se encontró config\credentials.json
    echo Copia tu archivo de credenciales de Google Cloud Console a:
    echo config\credentials.json
    echo.
    echo Puedes usar config\credentials.json.example como referencia
    echo.
)

if not exist "config\firebase-service-account.json" (
    echo.
    echo ¡IMPORTANTE! No se encontró config\firebase-service-account.json
    echo Copia tu archivo de credenciales de Firebase a:
    echo config\firebase-service-account.json
    echo.
    echo Puedes usar config\firebase-service-account.json.example como referencia
    echo.
)

REM Iniciar el servidor
echo Iniciando servidor en http://localhost:8000
echo Documentación disponible en http://localhost:8000/docs
echo.
echo Presiona Ctrl+C para detener el servidor
echo.

python -m app.main
