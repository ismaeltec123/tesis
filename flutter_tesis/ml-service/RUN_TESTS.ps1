# Test simple del microservicio ML
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🧪 TESTING ML SERVICE" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "[Test 1] Health Check..." -ForegroundColor Green
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get
    Write-Host "✅ Service is healthy!" -ForegroundColor Green
    Write-Host "   Status: $($health.status)" -ForegroundColor Gray
    Write-Host "   Prophet version: $($health.prophet_version)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Health check failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Train Usuario Nuevo (debería fallar)
Write-Host "[Test 2] Train Usuario Nuevo (should fail - insufficient data)..." -ForegroundColor Green
try {
    $body = Get-Content "test_data\test_usuario_nuevo.json" -Raw
    $response = Invoke-RestMethod -Uri "http://localhost:5000/train" -Method Post -Body $body -ContentType "application/json"
    
    if ($response.status -eq "insufficient_data") {
        Write-Host "✅ Correctly detected insufficient data!" -ForegroundColor Green
        Write-Host "   Events: $($response.events_provided) / $($response.minimum_required)" -ForegroundColor Gray
        Write-Host "   Weeks: $($response.weeks_of_data) / $($response.minimum_required_weeks)" -ForegroundColor Gray
        Write-Host "   Days until ready: $($response.days_until_ready)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Unexpected response: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Train failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 3: Train Usuario Listo (debería funcionar)
Write-Host "[Test 3] Train Usuario Listo (should succeed)..." -ForegroundColor Green
try {
    $body = Get-Content "test_data\test_usuario_listo.json" -Raw
    $response = Invoke-RestMethod -Uri "http://localhost:5000/train" -Method Post -Body $body -ContentType "application/json"
    
    if ($response.status -eq "trained") {
        Write-Host "✅ Model trained successfully!" -ForegroundColor Green
        Write-Host "   User ID: $($response.user_id)" -ForegroundColor Gray
        Write-Host "   Events used: $($response.events_used)" -ForegroundColor Gray
        Write-Host "   Weeks of data: $($response.weeks_of_data)" -ForegroundColor Gray
        Write-Host "   Training time: $($response.training_time_seconds)s" -ForegroundColor Gray
        Write-Host "   Can predict: $($response.can_predict)" -ForegroundColor Gray
        Write-Host "   Prophet components:" -ForegroundColor Gray
        Write-Host "     - Trend: $($response.prophet_components.trend_detected)" -ForegroundColor Gray
        Write-Host "     - Weekly: $($response.prophet_components.weekly_seasonality)" -ForegroundColor Gray
        Write-Host "     - Daily: $($response.prophet_components.daily_seasonality)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Unexpected response: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Train failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 4: Check Status
Write-Host "[Test 4] Check User Status..." -ForegroundColor Green
try {
    $status = Invoke-RestMethod -Uri "http://localhost:5000/status/test_user_listo" -Method Get
    Write-Host "✅ Status retrieved!" -ForegroundColor Green
    Write-Host "   Model exists: $($status.model_exists)" -ForegroundColor Gray
    Write-Host "   Can predict: $($status.can_predict)" -ForegroundColor Gray
    Write-Host "   ML readiness: $($status.ml_readiness)" -ForegroundColor Gray
    Write-Host "   Events in model: $($status.events_in_model)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Status check failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 5: Predict Reschedule
Write-Host "[Test 5] Predict Reschedule..." -ForegroundColor Green
try {
    $body = Get-Content "test_data\test_predict_request.json" -Raw
    $response = Invoke-RestMethod -Uri "http://localhost:5000/predict" -Method Post -Body $body -ContentType "application/json"
    
    if ($response.status -eq "success") {
        Write-Host "✅ Predictions generated!" -ForegroundColor Green
        Write-Host "   Confidence: $($response.confidence)" -ForegroundColor Gray
        Write-Host "   Recommendations: $($response.recommendations.Count)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   Top 3 Suggestions:" -ForegroundColor Cyan
        
        for ($i = 0; $i -lt [Math]::Min(3, $response.recommendations.Count); $i++) {
            $rec = $response.recommendations[$i]
            Write-Host "   [$($i+1)] $($rec.day_name) $($rec.hour):00 - Score: $($rec.score)" -ForegroundColor White
            Write-Host "       Probability: $($rec.completion_probability * 100)%" -ForegroundColor Gray
            Write-Host "       ML Confidence: $($rec.ml_confidence)" -ForegroundColor Gray
            if ($rec.reasons.Count -gt 0) {
                Write-Host "       Reason: $($rec.reasons[0])" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "⚠️  Unexpected response: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Predict failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ ALL TESTS COMPLETED!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
