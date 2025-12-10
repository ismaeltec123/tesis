# Test del Microservicio ML
# Puerto 5000

Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host "🤖 TEST MICROSERVICIO ML - PROPHET" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host ""

# 1. Health Check
Write-Host "1️⃣  Health Check..." -ForegroundColor Green
$health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get
Write-Host "   Status: $($health.status)" -ForegroundColor Cyan
Write-Host "   Service: $($health.service)" -ForegroundColor Cyan
Write-Host ""

# 2. Preparar datos de entrenamiento desde temp_events.json
Write-Host "2️⃣  Preparando datos de entrenamiento..." -ForegroundColor Green
$eventsData = Get-Content "c:\sdk\tesis\flutter_tesis\google-calendar-backend\temp_events.json" | ConvertFrom-Json
Write-Host "   Eventos cargados: $($eventsData.events.Count)" -ForegroundColor Cyan

# Convertir al formato esperado por el ML service
$trainingData = @{
    user_id = "ismael.qa13@gmail.com"
    events_history = @()
}

foreach ($event in $eventsData.events) {
    $mlEvent = @{
        id = $event.firebase_id
        date = $event.date
        status = $event.status
        type = $event.category  # Usar category como type
        title = $event.title
    }
    
    # Agregar reschedule_reason si no fue completado
    if ($event.status -ne "completado") {
        $mlEvent.reschedule_reason = $event.status
    }
    
    $trainingData.events_history += $mlEvent
}

Write-Host "   Eventos preparados para ML: $($trainingData.events_history.Count)" -ForegroundColor Cyan
Write-Host ""

# 3. Entrenar modelo
Write-Host "3️⃣  Entrenando modelo Prophet..." -ForegroundColor Green
$trainingJson = $trainingData | ConvertTo-Json -Depth 10
$trainResponse = Invoke-RestMethod -Uri "http://localhost:5000/train" -Method Post -Body $trainingJson -ContentType "application/json"

Write-Host "   Status: $($trainResponse.status)" -ForegroundColor Cyan
Write-Host "   User: $($trainResponse.user_id)" -ForegroundColor Cyan
Write-Host "   Eventos entrenados: $($trainResponse.events_trained)" -ForegroundColor Cyan
Write-Host "   Preparación ML: $($trainResponse.ml_readiness)" -ForegroundColor Yellow
Write-Host ""

# 4. Verificar estado del modelo
Write-Host "4️⃣  Verificando estado del modelo..." -ForegroundColor Green
$status = Invoke-RestMethod -Uri "http://localhost:5000/status/ismael.qa13@gmail.com" -Method Get
Write-Host "   Modelo existe: $($status.model_exists)" -ForegroundColor Cyan
Write-Host "   Puede predecir: $($status.can_predict)" -ForegroundColor Cyan
Write-Host "   Eventos en modelo: $($status.events_in_model)" -ForegroundColor Cyan
Write-Host "   Semanas de datos: $($status.weeks_of_data)" -ForegroundColor Cyan
Write-Host "   Estado ML: $($status.ml_readiness)" -ForegroundColor Yellow
Write-Host ""

# 5. Hacer predicción
Write-Host "5️⃣  Generando predicciones de horarios óptimos..." -ForegroundColor Green
$predictionRequest = @{
    user_id = "ismael.qa13@gmail.com"
    event = @{
        title = "Estudiar Machine Learning"
        type = "estudio"
        duration_hours = 2
    }
    preferences = @{
        preferred_days = @(0, 1, 2, 3, 4)  # Lunes a Viernes
        time_range = @{
            earliest_hour = 8
            latest_hour = 22
        }
    }
} | ConvertTo-Json -Depth 10

try {
    $prediction = Invoke-RestMethod -Uri "http://localhost:5000/predict" -Method Post -Body $predictionRequest -ContentType "application/json"
    
    Write-Host "   ✅ Predicción exitosa!" -ForegroundColor Green
    Write-Host "   Usuario: $($prediction.user_id)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   📅 SUGERENCIAS DE HORARIOS:" -ForegroundColor Yellow
    Write-Host ""
    
    $i = 1
    foreach ($sugg in $prediction.suggestions) {
        Write-Host "   Sugerencia $i" -ForegroundColor Magenta
        Write-Host "      Fecha: $($sugg.suggested_date)" -ForegroundColor White
        Write-Host "      Hora: $($sugg.suggested_hour):00" -ForegroundColor White
        Write-Host "      Confianza: $([math]::Round($sugg.confidence * 100, 1))%" -ForegroundColor White
        $reason = $sugg.reason
        Write-Host "      Razon: $reason" -ForegroundColor Gray
        Write-Host ""
        $i++
    }
    
} catch {
    Write-Host "   ⚠️  Error en predicción: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host "✅ TEST COMPLETADO" -ForegroundColor Green
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Siguiente paso: Integrar predicciones con calendario Flutter" -ForegroundColor Yellow
Write-Host "   - El ML service está listo para recibir eventos" -ForegroundColor Gray
Write-Host "   - Usa POST /predict para obtener 3 sugerencias de horarios" -ForegroundColor Gray
Write-Host "   - El usuario elige cuál crear automáticamente" -ForegroundColor Gray
