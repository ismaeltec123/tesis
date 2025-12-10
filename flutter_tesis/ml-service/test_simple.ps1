# Test ML Service
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "ML MICROSERVICE TEST" -ForegroundColor Yellow
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Health Check
Write-Host "1. Health Check..." -ForegroundColor Green
$health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get
Write-Host "   Status: $($health.status)" -ForegroundColor Cyan
Write-Host ""

# 2. Preparar datos
Write-Host "2. Preparando datos de entrenamiento..." -ForegroundColor Green
$eventsData = Get-Content "c:\sdk\tesis\flutter_tesis\google-calendar-backend\temp_events.json" | ConvertFrom-Json
Write-Host "   Eventos cargados: $($eventsData.events.Count)" -ForegroundColor Cyan

$trainingData = @{
    user_id = "ismael.qa13@gmail.com"
    events_history = @()
}

foreach ($event in $eventsData.events) {
    $mlEvent = @{
        id = $event.firebase_id
        date = $event.date
        status = $event.status
        type = $event.category
        title = $event.title
    }
    
    if ($event.status -ne "completado") {
        $mlEvent.reschedule_reason = $event.status
    }
    
    $trainingData.events_history += $mlEvent
}

Write-Host "   Eventos preparados: $($trainingData.events_history.Count)" -ForegroundColor Cyan
Write-Host ""

# 3. Entrenar modelo
Write-Host "3. Entrenando modelo Prophet..." -ForegroundColor Green
$trainingJson = $trainingData | ConvertTo-Json -Depth 10
$trainResponse = Invoke-RestMethod -Uri "http://localhost:5000/train" -Method Post -Body $trainingJson -ContentType "application/json"

Write-Host "   Status: $($trainResponse.status)" -ForegroundColor Cyan
Write-Host "   User: $($trainResponse.user_id)" -ForegroundColor Cyan
Write-Host "   Eventos: $($trainResponse.events_trained)" -ForegroundColor Cyan
Write-Host "   ML Ready: $($trainResponse.ml_readiness)" -ForegroundColor Yellow
Write-Host ""

# 4. Estado del modelo
Write-Host "4. Estado del modelo..." -ForegroundColor Green
$status = Invoke-RestMethod -Uri "http://localhost:5000/status/ismael.qa13@gmail.com" -Method Get
Write-Host "   Modelo existe: $($status.model_exists)" -ForegroundColor Cyan
Write-Host "   Puede predecir: $($status.can_predict)" -ForegroundColor Cyan
Write-Host "   Eventos: $($status.events_in_model)" -ForegroundColor Cyan
Write-Host "   Semanas: $($status.weeks_of_data)" -ForegroundColor Cyan
Write-Host ""

# 5. Prediccion
Write-Host "5. Generando predicciones..." -ForegroundColor Green
$predictionRequest = @{
    user_id = "ismael.qa13@gmail.com"
    event = @{
        title = "Estudiar Machine Learning"
        type = "estudio"
        duration_hours = 2
    }
    preferences = @{
        preferred_days = @(0, 1, 2, 3, 4)
        time_range = @{
            earliest_hour = 8
            latest_hour = 22
        }
    }
} | ConvertTo-Json -Depth 10

$prediction = Invoke-RestMethod -Uri "http://localhost:5000/predict" -Method Post -Body $predictionRequest -ContentType "application/json"

Write-Host "   Usuario: $($prediction.user_id)" -ForegroundColor Cyan
Write-Host ""
Write-Host "   SUGERENCIAS:" -ForegroundColor Yellow
Write-Host ""

$i = 1
foreach ($sugg in $prediction.suggestions) {
    Write-Host "   Sugerencia $i" -ForegroundColor Magenta
    Write-Host "      Fecha: $($sugg.suggested_date)" -ForegroundColor White
    Write-Host "      Hora: $($sugg.suggested_hour):00" -ForegroundColor White
    Write-Host "      Confianza: $([math]::Round($sugg.confidence * 100, 1))%" -ForegroundColor White
    Write-Host "      Razon: $($sugg.reason)" -ForegroundColor Gray
    Write-Host ""
    $i++
}

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETADO" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
