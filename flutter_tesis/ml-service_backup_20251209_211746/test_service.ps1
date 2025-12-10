# Test script for Windows PowerShell

Write-Host "================================" -ForegroundColor Cyan
Write-Host "🤖 ML Service - Test 1: Train Usuario Nuevo" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Debería fallar por datos insuficientes..." -ForegroundColor Gray
Write-Host ""

$body1 = Get-Content "test_data\test_usuario_nuevo.json" -Raw
Invoke-RestMethod -Uri "http://localhost:5000/train" -Method Post -Body $body1 -ContentType "application/json" | ConvertTo-Json -Depth 10

Write-Host "`n"
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🤖 ML Service - Test 2: Train Usuario Aprendiendo" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$body2 = Get-Content "test_data\test_usuario_aprendiendo.json" -Raw
Invoke-RestMethod -Uri "http://localhost:5000/train" -Method Post -Body $body2 -ContentType "application/json" | ConvertTo-Json -Depth 10

Write-Host "`n"
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🤖 ML Service - Test 3: Train Usuario Listo" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$body3 = Get-Content "test_data\test_usuario_listo.json" -Raw
Invoke-RestMethod -Uri "http://localhost:5000/train" -Method Post -Body $body3 -ContentType "application/json" | ConvertTo-Json -Depth 10

Write-Host "`n"
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🤖 ML Service - Test 4: Status Usuario Listo" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Invoke-RestMethod -Uri "http://localhost:5000/status/test_user_listo" -Method Get | ConvertTo-Json -Depth 10

Write-Host "`n"
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🤖 ML Service - Test 5: Predict Reschedule" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$body5 = Get-Content "test_data\test_predict_request.json" -Raw
Invoke-RestMethod -Uri "http://localhost:5000/predict" -Method Post -Body $body5 -ContentType "application/json" | ConvertTo-Json -Depth 10

Write-Host "`n"
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🤖 ML Service - Test 6: List All Models" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Invoke-RestMethod -Uri "http://localhost:5000/models" -Method Get | ConvertTo-Json -Depth 10

Write-Host "`n"
Write-Host "✅ Tests completed!" -ForegroundColor Green
