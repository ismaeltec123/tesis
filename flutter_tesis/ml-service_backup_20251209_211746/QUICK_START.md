# Quick Start Guide - ML Service

## 🚀 Inicio Rápido (3 pasos)

### 1. Instalar dependencias

```bash
cd ml-service
pip install -r requirements.txt
```

### 2. Iniciar servicio

**Windows:**
```bash
START_ML_SERVICE.bat
```

**Linux/Mac:**
```bash
python app.py
```

### 3. Probar endpoints

**Windows PowerShell:**
```bash
.\test_service.ps1
```

**Linux/Mac:**
```bash
chmod +x test_service.sh
./test_service.sh
```

---

## 📡 Endpoints Disponibles

### Health Check
```bash
curl http://localhost:5000/health
```

### Entrenar Modelo (Usuario Nuevo - Fallará)
```bash
curl -X POST http://localhost:5000/train ^
  -H "Content-Type: application/json" ^
  -d @test_data/test_usuario_nuevo.json
```

**Respuesta esperada:** `status: insufficient_data`

### Entrenar Modelo (Usuario Listo - Éxito)
```bash
curl -X POST http://localhost:5000/train ^
  -H "Content-Type: application/json" ^
  -d @test_data/test_usuario_listo.json
```

**Respuesta esperada:** `status: trained`, modelo guardado en `models/user_test_user_listo.pkl`

### Ver Estado de Usuario
```bash
curl http://localhost:5000/status/test_user_listo
```

### Predecir Reagendamiento
```bash
curl -X POST http://localhost:5000/predict ^
  -H "Content-Type: application/json" ^
  -d @test_data/test_predict_request.json
```

**Respuesta esperada:** Top 3 sugerencias con scores Prophet

### Listar Modelos
```bash
curl http://localhost:5000/models
```

---

## 🧪 Casos de Prueba

### Caso 1: Usuario Nuevo (5 eventos, 4 días)
- **Archivo:** `test_data/test_usuario_nuevo.json`
- **Resultado esperado:** `insufficient_data`
- **Razón:** Menos de 20 eventos y menos de 2 semanas

### Caso 2: Usuario Aprendiendo (22 eventos, 19 días)
- **Archivo:** `test_data/test_usuario_aprendiendo.json`
- **Resultado esperado:** `trained` con confianza `medium`
- **Prophet:** Configuración básica (solo weekly seasonality)

### Caso 3: Usuario Listo (58 eventos, 56 días)
- **Archivo:** `test_data/test_usuario_listo.json`
- **Resultado esperado:** `trained` con confianza `high`
- **Prophet:** Configuración completa (weekly + daily seasonality)

---

## 📊 Verificar Funcionamiento

### 1. Health Check
```bash
curl http://localhost:5000/health
```

Debe responder:
```json
{
  "status": "healthy",
  "service": "ML Rescheduling Service",
  "prophet_version": "1.1.5"
}
```

### 2. Entrenar Usuario Listo
```bash
curl -X POST http://localhost:5000/train ^
  -H "Content-Type: application/json" ^
  -d @test_data/test_usuario_listo.json
```

Debe responder:
```json
{
  "status": "trained",
  "can_predict": true,
  "events_used": 58,
  "weeks_of_data": 8.0,
  "prophet_components": {
    "trend_detected": true,
    "weekly_seasonality": true,
    "daily_seasonality": true
  }
}
```

### 3. Predecir Reagendamiento
```bash
curl -X POST http://localhost:5000/predict ^
  -H "Content-Type: application/json" ^
  -d @test_data/test_predict_request.json
```

Debe responder:
```json
{
  "status": "success",
  "confidence": "high",
  "recommendations": [
    {
      "date": "2025-12-10T10:00:00",
      "score": 0.92,
      "completion_probability": 0.89,
      "reasons": [
        "Prophet predice 89% de éxito basado en tus patrones históricos",
        "Horario matutino con alta energía típica"
      ]
    }
  ]
}
```

---

## 🐳 Docker

### Build
```bash
docker build -t ml-service .
```

### Run
```bash
docker run -p 5000:5000 ml-service
```

---

## 🔍 Logs y Debug

El servicio imprime logs detallados:

```
🤖 ML RESCHEDULING SERVICE STARTING...
📊 Using: Facebook Prophet ML Model
🚀 Server running on http://localhost:5000

📊 Training request for user: test_user_listo
   Events provided: 58
   Sufficient data, training Prophet model...
   Prophet data prepared: 58 data points
   Using full Prophet config (weeks_of_data: 8.0)
   Training Prophet model...
   ✅ Training completed in 2.35s
   💾 Model saved: models/user_test_user_listo.pkl
```

---

## ❌ Troubleshooting

### Error: ModuleNotFoundError: No module named 'prophet'
```bash
pip install prophet==1.1.5
```

### Error: Microsoft Visual C++ required (Windows)
Instalar: https://visualstudio.microsoft.com/visual-cpp-build-tools/

### Error: Port 5000 already in use
Cambiar puerto en `app.py`:
```python
app.run(host='0.0.0.0', port=5001, debug=True)
```

---

## 📈 Próximos Pasos

1. ✅ Microservicio funcional
2. ✅ Prophet integrado
3. ✅ Tests completos
4. ⏳ Integrar con Backend Principal
5. ⏳ Deploy en Docker

---

## 🎯 Para Presentación

**Demostración:**
1. Mostrar health check
2. Entrenar usuario nuevo (falla por datos insuficientes)
3. Entrenar usuario listo (éxito)
4. Mostrar estado del modelo
5. Generar predicciones con Prophet
6. Explicar los 3 estados: NUEVO → APRENDIENDO → LISTO
