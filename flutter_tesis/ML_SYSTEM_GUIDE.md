# 🤖 Sistema ML de Análisis de Patrones de Eventos

## Descripción General

Sistema de Machine Learning que analiza patrones de cancelación y no realización de eventos para:
- **Predecir** cuándo es más probable que el usuario falle en sus eventos
- **Identificar** días y horarios problemáticos
- **Sugerir** mejores horarios basados en patrones de éxito históricos
- **Reprogramar** eventos automáticamente a horarios más convenientes

---

## 🎯 Características Principales

### 1. Análisis de Patrones
- ✅ Analiza todos los eventos del usuario
- ✅ Calcula tasas de falla por:
  - Día de la semana (Lunes-Domingo)
  - Franja horaria (06:00-08:00, 08:00-10:00, etc.)
  - Tipo de evento (estudio, recreativo, personal, obligatorio)
  - Fin de semana vs día de semana
- ✅ Identifica "puntos calientes" de falla
- ✅ Muestra eventos fallidos recientes

### 2. Predicción de Riesgo
- ✅ Predice probabilidad de falla (0-100%)
- ✅ Clasifica riesgo: BAJO 🟢, MEDIO 🟡, ALTO 🔴
- ✅ Explica razones del riesgo
- ✅ Genera recomendaciones personalizadas

### 3. Sugerencias de Reprogramación
- ✅ Sugiere mejores días y horarios
- ✅ Combina patrones exitosos
- ✅ Calcula confianza de cada sugerencia
- ✅ Mantiene duración del evento original

### 4. Generación de Datos de Prueba
- ✅ Autorellena eventos con estados de falla
- ✅ Simula patrones realistas
- ✅ Útil para demostración y testing

---

## 🚀 Cómo Usar el Sistema

### En Flutter (Frontend)

#### 1. Abrir el Análisis ML
```dart
// En calendar_view.dart hay un botón flotante rosa con ícono de insights
FloatingActionButton(
  heroTag: "ml_patterns",
  icon: Icons.insights,
  onPressed: () => _showMLPatternDialog(context),
)
```

**Ubicación**: Botón flotante superior derecho con gradiente rosa/fucsia

#### 2. Generar Datos de Prueba
```dart
// Dentro del diálogo ML Pattern Analysis
TextButton.icon(
  onPressed: _generateTestData,
  icon: Icon(Icons.science),
  label: Text('Generar Datos de Prueba'),
)
```

**Acción**: Marca 5 eventos pendientes como cancelados/no realizados en horarios problemáticos

#### 3. Ver Análisis Completo
El diálogo muestra:
- **Resumen General**: Total eventos, eventos fallidos, tasa de falla
- **Peores Días**: Días con mayor tasa de cancelación
- **Peores Horarios**: Franjas horarias más problemáticas
- **Mejores Alternativas**: Días y horarios recomendados

---

## 📡 Backend API Endpoints

### Base URL
```
http://localhost:8001/api/ml
```

### 1. Analizar Patrones
```http
GET /ml/analyze-patterns?user_id=estudiante_demo
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_events": 50,
      "failed_events": 12,
      "failure_rate": 24.0,
      "analysis_date": "2025-11-13T..."
    },
    "failure_by_day": {
      "Lunes": {"total": 10, "failed": 5, "rate": 50.0},
      "Martes": {"total": 8, "failed": 2, "rate": 25.0},
      ...
    },
    "failure_by_time_slot": {
      "06:00-08:00": {"total": 5, "failed": 4, "rate": 80.0},
      "08:00-10:00": {"total": 12, "failed": 3, "rate": 25.0},
      ...
    },
    "worst_patterns": {
      "days": [
        {"day": "Lunes", "rate": 50.0, "failed": 5},
        ...
      ],
      "time_slots": [
        {"slot": "06:00-08:00", "rate": 80.0, "failed": 4},
        ...
      ]
    },
    "best_patterns": {
      "days": [...],
      "time_slots": [...]
    }
  }
}
```

### 2. Predecir Riesgo de Evento
```http
POST /ml/predict-risk?user_id=estudiante_demo
Content-Type: application/json

{
  "id": "event123",
  "title": "Estudiar matemáticas",
  "date": "2025-11-14T06:00:00",
  "endTime": "2025-11-14T08:00:00",
  "type": "estudio",
  "status": "pendiente"
}
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "event_id": "event123",
    "event_title": "Estudiar matemáticas",
    "risk_score": 65.5,
    "risk_level": "ALTO",
    "risk_color": "red",
    "current_schedule": {
      "day": "Jueves",
      "time_slot": "06:00-08:00",
      "hour": "06:00"
    },
    "reasons": [
      "Los Juevess tienen 50% de falla",
      "La franja 06:00-08:00 tiene 80% de falla"
    ],
    "recommendations": [
      "Mejor día: Martes (25% falla)",
      "Mejor horario: 10:00-12:00 (15% falla)"
    ],
    "should_reschedule": true
  }
}
```

### 3. Sugerir Reprogramación
```http
POST /ml/suggest-reschedule?user_id=estudiante_demo
Content-Type: application/json

{
  "id": "event123",
  "title": "Estudiar matemáticas",
  "date": "2025-11-14T06:00:00",
  "endTime": "2025-11-14T08:00:00",
  "type": "estudio"
}
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "event_id": "event123",
    "event_title": "Estudiar matemáticas",
    "current_schedule": {
      "date": "2025-11-14T06:00:00",
      "day": "Jueves"
    },
    "suggestions": [
      {
        "suggested_start": "2025-11-19T10:00:00",
        "suggested_end": "2025-11-19T12:00:00",
        "day": "Martes",
        "time_slot": "10:00-12:00",
        "hour": "10:00",
        "failure_rate": 20.0,
        "reason": "Combina Martes (25% falla) con horario 10:00-12:00 (15% falla)",
        "confidence": 80.0
      },
      ...
    ]
  }
}
```

### 4. Autorrellenar Datos de Prueba
```http
POST /ml/auto-fill-test-data?user_id=estudiante_demo&num_events=5
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "modified_count": 5,
    "requested": 5,
    "modified_events": [
      {
        "id": "event456",
        "title": "Clase de física",
        "day": "Lunes",
        "time_slot": "06:00-08:00",
        "old_status": "pendiente",
        "new_status": "cancelado",
        "reason": "Evento en Lunes - 06:00-08:00 (horario problemático)"
      },
      ...
    ],
    "message": "Se marcaron 5 eventos como cancelados/no realizados para análisis ML"
  }
}
```

### 5. Obtener Hotspots de Falla
```http
GET /ml/get-failure-hotspots?user_id=estudiante_demo
```

**Respuesta** (versión simplificada del análisis):
```json
{
  "success": true,
  "data": {
    "summary": {...},
    "worst_days": [...],
    "worst_time_slots": [...],
    "best_days": [...],
    "best_time_slots": [...],
    "weekend_vs_weekday": {...}
  }
}
```

### 6. Estadísticas del Sistema ML
```http
GET /ml/stats
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "name": "Event Pattern Analyzer",
    "version": "1.0.0",
    "capabilities": [
      "Análisis de patrones de cancelación",
      "Predicción de riesgo de eventos",
      "Sugerencias de reprogramación inteligente",
      ...
    ],
    "features_analyzed": [
      "day_of_week",
      "hour",
      "time_slot",
      "event_type",
      "duration",
      "is_weekend"
    ],
    "status_tracked": [
      "pendiente",
      "confirmado",
      "completado",
      "no_realizado",
      "cancelado",
      "postergado"
    ]
  }
}
```

---

## 🧪 Flujo de Testing

### 1. Generar Datos Iniciales
```bash
# Iniciar backend
cd google-calendar-backend
python simple_server.py

# El sistema necesita al menos 5 eventos con estados para funcionar
```

### 2. Crear Eventos de Prueba
Desde Flutter:
1. Crear varios eventos en diferentes días y horarios
2. Marcar algunos como "cancelado" o "no realizado"
3. O usar el botón "Generar Datos de Prueba" en el diálogo ML

### 3. Ver Análisis
1. Click en botón rosa "Insights" (superior derecho)
2. Esperar análisis (2-5 segundos)
3. Ver patrones identificados

### 4. Predecir Riesgo
El sistema automáticamente evalúa cada evento y muestra:
- 🔴 Eventos de alto riesgo
- 🟡 Eventos de riesgo medio  
- 🟢 Eventos de bajo riesgo

---

## 📊 Algoritmo ML Simplificado

```python
# Cálculo de riesgo ponderado
risk_score = (
    day_failure_rate * 0.4 +      # 40% peso en día de semana
    time_slot_failure_rate * 0.4 + # 40% peso en franja horaria
    type_failure_rate * 0.2        # 20% peso en tipo de evento
)

# Clasificación
if risk_score >= 60:
    risk_level = "ALTO"    # 🔴
elif risk_score >= 30:
    risk_level = "MEDIO"   # 🟡
else:
    risk_level = "BAJO"    # 🟢
```

---

## 📁 Archivos Creados

### Backend (Python)
```
google-calendar-backend/
├── ml_pattern_analyzer.py          # Lógica ML principal
└── app/routes/ml_routes.py         # Endpoints FastAPI
```

### Frontend (Flutter)
```
tesis/lib/
├── services/ml_pattern_service.dart   # Cliente HTTP
└── widgets/ml_pattern_dialog.dart     # UI del diálogo
```

### Integración
```
tesis/lib/views/calendar_view.dart     # Botón + método _showMLPatternDialog
google-calendar-backend/simple_server.py  # Registro de rutas ML
```

---

## 🎨 UI Components

### Botón ML Pattern Analysis
- **Color**: Gradiente rosa/fucsia (#E91E63 → #C2185B)
- **Ícono**: `Icons.insights`
- **Ubicación**: FloatingActionButton superior (encima de IA)
- **Tooltip**: "Análisis ML de Patrones"

### Diálogo ML Pattern Analysis
- **Tamaño**: 90% ancho, 80% alto
- **Secciones**:
  1. **Header**: Título + ícono `psychology`
  2. **Resumen**: 3 tarjetas con stats
  3. **Peores Días**: Tarjeta roja con lista
  4. **Peores Horarios**: Tarjeta naranja con lista
  5. **Mejores Alternativas**: Tarjeta verde con recomendaciones
  6. **Footer**: Botón "Generar Datos de Prueba"

---

## 🔧 Configuración

### Requisitos Backend
```python
# Ya incluidos en requirements.txt
numpy
firebase-admin
fastapi
uvicorn
```

### Requisitos Flutter
```yaml
# pubspec.yaml (ya incluidos)
dependencies:
  http: ^1.1.0
  provider: ^6.0.5
  intl: ^0.18.1
```

---

## 📝 Casos de Uso

### Caso 1: Estudiante con muchas cancelaciones en las mañanas
**Problema**: 80% de falla en eventos de 06:00-08:00

**Solución ML**:
1. Sistema detecta patrón: "Franja 06:00-08:00 tiene 80% falla"
2. Sugiere: "Reprogramar a 10:00-12:00 (15% falla)"
3. Usuario acepta y eventos se mueven automáticamente

### Caso 2: Eventos de ejercicio cancelados los lunes
**Problema**: 60% de eventos de ejercicio cancelados los lunes

**Solución ML**:
1. Sistema identifica: "Lunes + ejercicio = 60% falla"
2. Recomienda: "Mejor día: Miércoles (20% falla)"
3. Usuario puede ver alternativas y elegir

### Caso 3: Fin de semana vs días de semana
**Problema**: Usuario tiene 45% falla en fin de semana vs 15% entre semana

**Solución ML**:
1. Muestra estadística clara: "Weekday: 15% | Weekend: 45%"
2. Sugiere: "Evita programar eventos importantes en fin de semana"

---

## 🚀 Próximas Mejoras

- [ ] Integración con AI Organizer para sugerencias automáticas
- [ ] Notificaciones cuando un evento tiene alto riesgo
- [ ] Opción de reprogramar con un click desde el análisis
- [ ] Gráficos visuales de patrones (charts)
- [ ] Exportar reporte PDF del análisis
- [ ] Comparar patrones entre semanas/meses
- [ ] Machine Learning más avanzado (sklearn, TensorFlow)

---

## 📞 Soporte

Si encuentras errores:
1. Verifica que el backend esté corriendo en puerto 8001
2. Revisa logs en consola de Python
3. Asegúrate de tener eventos con estados variados
4. Usa "Generar Datos de Prueba" si no tienes suficientes eventos

---

**✅ Sistema ML completamente funcional y listo para usar!**
