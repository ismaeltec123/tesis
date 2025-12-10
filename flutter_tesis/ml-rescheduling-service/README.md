# ML Rescheduling Service

Microservicio de Machine Learning para recomendación inteligente de reagendamiento de eventos.

## 🎯 Funcionalidad

Este servicio analiza patrones históricos de completación de eventos del usuario y recomienda los mejores horarios para reagendar eventos no completados.

## 🧠 Modelos Utilizados

### 1. **Prophet (Facebook)** - Para usuarios con >15 eventos
- Modelo de forecasting de series temporales
- Paper: Taylor & Letham (2017) "Forecasting at Scale"
- Predice productividad futura basándose en patrones pasados
- Maneja estacionalidad semanal y diaria automáticamente

### 2. **Statistical Heuristics ML** - Para usuarios con <15 eventos
- Análisis estadístico de patrones de completación
- Regresión lineal ponderada con 4 features principales
- No requiere entrenamiento previo

## 📊 Features (Características) del Modelo

El sistema analiza:
- **Temporales**: Hora del día, día de la semana, estacionalidad
- **Históricas**: Tasa de completación por hora/día/tipo
- **Contextuales**: Densidad del calendario, gaps antes/después
- **Tipo de evento**: Estudio, trabajo, ejercicio, personal

## 🚀 Instalación Rápida

```bash
# Instalar dependencias
pip install -r requirements.txt

# Ejecutar servidor
python app.py
```

El servicio estará disponible en `http://localhost:5000`

## 📡 API Endpoints

### 1. Health Check
```bash
GET /health
```

### 2. Recomendar Reagendamiento
```bash
POST /reschedule
Content-Type: application/json

{
  "user_id": "user123",
  "event": {
    "id": "evt_456",
    "title": "Estudiar Matemáticas",
    "type": "estudio",
    "duration_minutes": 90,
    "original_date": "2025-12-09T20:00:00Z"
  },
  "user_history": [
    {
      "date": "2025-12-01T10:00:00Z",
      "status": "finalizado",
      "type": "estudio"
    }
  ],
  "future_calendar": []
}
```

**Response:**
```json
{
  "user_id": "user123",
  "original_event": {...},
  "recommendations": [
    {
      "rank": 1,
      "date": "2025-12-10T10:00:00Z",
      "day_name": "Martes",
      "hour": 10,
      "score": 0.89,
      "predicted_completion_probability": 0.89,
      "ml_confidence": "high",
      "reasons": [
        "El modelo ML predice alta probabilidad de éxito (89%) basado en tus patrones",
        "Horario matutino con alta energía típica",
        "Martes es un día con buena productividad general"
      ]
    }
  ],
  "ml_method": "Facebook Prophet ML Model",
  "confidence": "high",
  "data_points_used": 45
}
```

### 3. Analizar Patrones
```bash
POST /analyze
Content-Type: application/json

{
  "user_id": "user123",
  "user_history": [...]
}
```

## 🐳 Docker

```bash
# Construir imagen
docker build -t ml-rescheduling-service .

# Ejecutar contenedor
docker run -p 5000:5000 ml-rescheduling-service
```

## 🔗 Integración con Backend Principal

```python
# En tu backend FastAPI
import requests

def get_ml_recommendations(event, user_history):
    response = requests.post('http://ml-service:5000/reschedule', json={
        'user_id': user_id,
        'event': event,
        'user_history': user_history,
        'future_calendar': get_future_calendar(user_id)
    })
    return response.json()
```

## 📚 Referencias Académicas

1. **Prophet**: Taylor, S. J., & Letham, B. (2017). Forecasting at scale. The American Statistician, 72(1), 37-45.
2. **Time Series Forecasting**: Hyndman, R. J., & Athanasopoulos, G. (2021). Forecasting: principles and practice.
3. **Recommender Systems**: Ricci, F., et al. (2015). Recommender Systems Handbook.

## 🎓 Para Presentación de Tesis

**Justificación del enfoque**:
- Prophet es un modelo estado del arte de Facebook (2017), ampliamente usado en industria
- No requiere gran cantidad de datos para comenzar a funcionar
- Combina análisis estadístico con machine learning
- Genera predicciones interpretables (importante para tesis)
- Maneja estacionalidad y tendencias automáticamente

**Métricas evaluables**:
- Precisión de predicción (accuracy)
- Tasa de aceptación de recomendaciones por usuarios
- Reducción en reprogramaciones múltiples
- Mejora en tasa de completación de eventos

## 🛠️ Próximos Pasos

1. ✅ Implementación básica completa
2. ⏳ Dockerización
3. ⏳ Integración con backend principal
4. ⏳ Testing con datos reales
5. ⏳ Métricas y evaluación
