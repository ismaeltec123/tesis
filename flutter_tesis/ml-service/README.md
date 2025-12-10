# Microservicio de Machine Learning para Reagendamiento Inteligente

## 🤖 Descripción

Microservicio Flask que usa **Prophet (Facebook)** para predecir los mejores horarios de reagendamiento basándose en patrones históricos del usuario.

## 📦 Tecnologías

- **Flask 3.0.0** - API REST
- **Prophet 1.1.5** - Machine Learning para series temporales
- **Pandas 2.1.3** - Manipulación de datos
- **Joblib** - Persistencia de modelos

## 🚀 Instalación

```bash
cd ml-service
pip install -r requirements.txt
```

## ▶️ Ejecutar

```bash
python app.py
```

El servicio corre en: `http://localhost:5000`

## 📡 Endpoints

### 1. Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "ML Rescheduling Service",
  "prophet_version": "1.1.5",
  "timestamp": "2025-12-09T20:00:00"
}
```

### 2. Entrenar Modelo
```http
POST /train
Content-Type: application/json

{
  "user_id": "user123",
  "events_history": [
    {
      "id": "evt_1",
      "date": "2025-11-15T10:00:00Z",
      "status": "finalizado",
      "type": "estudio",
      "title": "Estudiar Cálculo"
    }
  ]
}
```

**Response (éxito):**
```json
{
  "status": "trained",
  "user_id": "user123",
  "events_used": 45,
  "weeks_of_data": 3.2,
  "training_time_seconds": 2.3,
  "can_predict": true,
  "prophet_components": {
    "trend_detected": true,
    "weekly_seasonality": true,
    "daily_seasonality": false
  }
}
```

**Response (datos insuficientes):**
```json
{
  "status": "insufficient_data",
  "user_id": "user123",
  "events_provided": 12,
  "minimum_required": 20,
  "weeks_of_data": 1.5,
  "minimum_required_weeks": 2,
  "days_until_ready": 4,
  "can_predict": false
}
```

### 3. Predecir Reagendamiento
```http
POST /predict
Content-Type: application/json

{
  "user_id": "user123",
  "incomplete_event": {
    "id": "evt_456",
    "title": "Estudiar Matemáticas",
    "type": "estudio",
    "duration_minutes": 90,
    "original_date": "2025-12-09T20:00:00Z",
    "reschedule_reason": "cansado"
  },
  "events_history": [...],
  "future_calendar": []
}
```

**Response:**
```json
{
  "status": "success",
  "user_id": "user123",
  "ml_method": "Prophet",
  "confidence": "high",
  "recommendations": [
    {
      "date": "2025-12-10T10:00:00",
      "day_name": "Martes",
      "hour": 10,
      "score": 0.92,
      "completion_probability": 0.89,
      "ml_confidence": "high",
      "reasons": [
        "Prophet predice 89% de éxito basado en tus patrones históricos",
        "Horario matutino con alta energía típica",
        "Martes es un día con buena productividad general"
      ],
      "prophet_details": {
        "yhat": 0.89,
        "yhat_lower": 0.75,
        "yhat_upper": 0.95,
        "trend_component": 0.65,
        "weekly_component": 0.24
      }
    }
  ],
  "metrics": {
    "total_events_analyzed": 45,
    "weeks_of_data": 3.2,
    "model_accuracy_estimate": 0.78,
    "candidates_generated": 168
  }
}
```

### 4. Estado del Usuario
```http
GET /status/<user_id>
```

**Response:**
```json
{
  "user_id": "user123",
  "model_exists": true,
  "can_predict": true,
  "last_training": "2025-12-09T15:30:00",
  "events_in_model": 45,
  "weeks_of_data": 3.2,
  "ml_readiness": "ready"
}
```

### 5. Listar Modelos
```http
GET /models
```

## 📊 Estados del Usuario

- **not_ready** - Menos de 2 semanas o menos de 20 eventos
- **learning** - Entre 2-4 semanas o 20-50 eventos
- **ready** - Más de 4 semanas y más de 50 eventos

## 🎯 Estados de Eventos (6 tipos)

El sistema reconoce estos estados y los evalúa diferente:

| Estado | Productividad | Descripción |
|--------|--------------|-------------|
| `completado` / `finalizado` | 1.0 (100%) | ✅ Evento completado exitosamente |
| `postergado` | 0.3 (30%) | ⚠️ Lo intentaste pero no pudiste |
| `no_realizado` | 0.0 (0%) | ❌ El evento pasó y no se hizo |
| `cancelado` | 0.0 (0%) | 🚫 Cancelado antes de la fecha |
| `pendiente` / `confirmado` | - | ⏳ Evento futuro (no se cuenta) |

## 🗓️ Detección de Conflictos

El ML **automáticamente filtra** horarios que:
- ✅ Ya están ocupados en tu calendario
- ✅ Se solapan con eventos existentes
- ✅ No tienen suficiente duración continua

**Ejemplo:** Si necesitas 2 horas y tienes evento de 2-3pm, el ML NO sugerirá 1-3pm

## 🧪 Probar con JSON

Ver archivos de prueba en `test_data/`:
- `test_usuario_nuevo.json` - Usuario sin datos suficientes
- `test_usuario_aprendiendo.json` - Usuario en fase de aprendizaje
- `test_usuario_listo.json` - Usuario con modelo completo

## 🐳 Docker

```bash
docker build -t ml-service .
docker run -p 5000:5000 ml-service
```

## 📁 Estructura

```
ml-service/
├── app.py                    # Flask API
├── requirements.txt          # Dependencias
├── services/
│   ├── prophet_trainer.py    # Entrenamiento Prophet
│   ├── prophet_predictor.py  # Predicciones
│   └── model_manager.py      # Persistencia de modelos
├── utils/
│   └── data_validator.py     # Validación de datos
├── models/                   # Modelos .pkl guardados
└── test_data/                # JSONs de prueba
```

## 🔬 Cómo Funciona Prophet

Prophet usa un modelo aditivo:

```
y(t) = g(t) + s(t) + h(t) + ε(t)
```

- **g(t)**: Tendencia - Cambio a largo plazo
- **s(t)**: Estacionalidad - Patrones semanales/diarios
- **h(t)**: Holidays - Eventos especiales
- **ε(t)**: Ruido - Variabilidad

## 📄 Paper

Taylor, S. J., & Letham, B. (2017). Forecasting at scale. *The American Statistician, 72*(1), 37-45.

## 🎯 Próximos Pasos

1. ✅ Microservicio funcional
2. ⏳ Crear JSONs de prueba
3. ⏳ Dockerizar
4. ⏳ Integrar con Backend Principal
