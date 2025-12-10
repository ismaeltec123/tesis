# Script de prueba completo del sistema
Write-Host "🧪 INICIANDO PRUEBAS DEL SISTEMA" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# 1. Verificar archivos críticos
Write-Host "`n📁 Verificando archivos críticos..." -ForegroundColor Yellow
$archivos = @(
    "google-calendar-backend\app\routes\calendar_routes.py",
    "google-calendar-backend\simple_server.py",
    "docker\app.py",
    "tesis\lib\services\teacher_schedule_service.dart",
    "admin-panel\src\App.tsx"
)

foreach ($archivo in $archivos) {
    if (Test-Path $archivo) {
        Write-Host "  ✅ $archivo" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $archivo NO EXISTE" -ForegroundColor Red
    }
}

# 2. Verificar servicios corriendo
Write-Host "`n🔄 Verificando servicios..." -ForegroundColor Yellow

$backend = Get-Process | Where-Object {$_.ProcessName -eq 'python'} | Select-Object -First 1
if ($backend) {
    Write-Host "  ✅ Backend Python corriendo (PID: $($backend.Id))" -ForegroundColor Green
} else {
    Write-Host "  ❌ Backend NO está corriendo" -ForegroundColor Red
}

$flutter = Get-Process | Where-Object {$_.ProcessName -eq 'dart'} | Select-Object -First 1
if ($flutter) {
    Write-Host "  ✅ Flutter corriendo (PID: $($flutter.Id))" -ForegroundColor Green
} else {
    Write-Host "  ❌ Flutter NO está corriendo" -ForegroundColor Red
}

# 3. Probar endpoints del backend
Write-Host "`n🌐 Probando endpoints..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8001/api/calendar/events" -Method GET -TimeoutSec 5
    Write-Host "  ✅ Backend respondiendo (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Backend no responde en puerto 8001" -ForegroundColor Red
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8002/" -Method GET -TimeoutSec 5
    Write-Host "  ✅ OCR Service respondiendo" -ForegroundColor Green
} catch {
    Write-Host "  ❌ OCR Service no responde en puerto 8002" -ForegroundColor Red
}

# 4. Verificar temp_events.json
Write-Host "`n📊 Verificando base de datos..." -ForegroundColor Yellow
$eventsFile = "google-calendar-backend\temp_events.json"
if (Test-Path $eventsFile) {
    $eventos = (Get-Content $eventsFile | ConvertFrom-Json).Count
    Write-Host "  ✅ $eventos eventos en base de datos" -ForegroundColor Green
} else {
    Write-Host "  ❌ temp_events.json no existe" -ForegroundColor Red
}

Write-Host "`n✅ PRUEBAS COMPLETADAS" -ForegroundColor Cyan
Write-Host "======================`n" -ForegroundColor Cyan
