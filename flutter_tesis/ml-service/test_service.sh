#!/bin/bash

echo "================================"
echo "🤖 ML Service - Test 1: Train Usuario Nuevo"
echo "================================"
echo ""
echo "Debería fallar por datos insuficientes..."
echo ""

curl -X POST http://localhost:5000/train \
  -H "Content-Type: application/json" \
  -d @test_data/test_usuario_nuevo.json

echo -e "\n\n"
echo "================================"
echo "🤖 ML Service - Test 2: Train Usuario Aprendiendo"
echo "================================"
echo ""

curl -X POST http://localhost:5000/train \
  -H "Content-Type: application/json" \
  -d @test_data/test_usuario_aprendiendo.json

echo -e "\n\n"
echo "================================"
echo "🤖 ML Service - Test 3: Train Usuario Listo"
echo "================================"
echo ""

curl -X POST http://localhost:5000/train \
  -H "Content-Type: application/json" \
  -d @test_data/test_usuario_listo.json

echo -e "\n\n"
echo "================================"
echo "🤖 ML Service - Test 4: Status Usuario Listo"
echo "================================"
echo ""

curl http://localhost:5000/status/test_user_listo

echo -e "\n\n"
echo "================================"
echo "🤖 ML Service - Test 5: Predict Reschedule"
echo "================================"
echo ""

curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d @test_data/test_predict_request.json

echo -e "\n\n"
echo "================================"
echo "🤖 ML Service - Test 6: List All Models"
echo "================================"
echo ""

curl http://localhost:5000/models

echo -e "\n\n"
echo "✅ Tests completed!"
