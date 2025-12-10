"""
Microservicio ML independiente para predicciones de calendario
Puerto: 5000
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import os

# Agregar el directorio app al path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from ml.ml_service import MLModels
from services.mock_firebase import MockFirebaseService
import json
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# Inicializar servicios
firebase = MockFirebaseService()
ml_models = None

def load_training_data():
    """Carga datos de entrenamiento desde temp_events.json"""
    try:
        with open('temp_events.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
            events = data.get('events', [])
            print(f"✅ Cargados {len(events)} eventos para entrenamiento ML")
            return events
    except Exception as e:
        print(f"❌ Error cargando datos: {e}")
        return []

@app.route('/health', methods=['GET'])
def health():
    """Health check del microservicio"""
    return jsonify({
        'status': 'ok',
        'service': 'ML Microservice',
        'port': 5000,
        'model_trained': ml_models is not None and ml_models.models_trained
    })

@app.route('/train', methods=['POST'])
def train_model():
    """Entrena el modelo ML con los datos históricos"""
    global ml_models
    
    try:
        # Cargar datos de entrenamiento
        events = load_training_data()
        
        if not events:
            return jsonify({
                'success': False,
                'error': 'No hay eventos para entrenar'
            }), 400
        
        # Inicializar y entrenar los modelos ML
        ml_models = MLModels()
        
        print(f"🤖 Entrenando modelos ML con {len(events)} eventos...")
        ml_models.train_models(events)
        
        # Obtener insights
        insights = ml_models.get_schedule_insights(events)
        
        print(f"✅ Modelos entrenados exitosamente")
        print(f"📊 Insights: {insights}")
        
        return jsonify({
            'success': True,
            'message': 'Modelos entrenados exitosamente',
            'events_count': len(events),
            'insights': insights
        })
        
    except Exception as e:
        print(f"❌ Error entrenando modelos: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/predict', methods=['POST'])
def predict():
    """
    Genera 3 sugerencias de tiempo para un nuevo evento
    
    Body:
    {
        "title": "Estudiar Matemáticas",
        "duration_minutes": 90,
        "preferred_days": [0, 1, 2, 3, 4],  # Opcional: días preferidos (0=Lunes)
        "constraints": {
            "earliest_hour": 8,
            "latest_hour": 22
        }
    }
    
    Respuesta:
    {
        "success": true,
        "suggestions": [
            {
                "date": "2025-12-11T10:00:00",
                "end_time": "2025-12-11T11:30:00",
                "confidence": 0.92,
                "reason": "Alta productividad en mañanas entre semana"
            },
            {
                "date": "2025-12-11T15:00:00",
                "end_time": "2025-12-11T16:30:00",
                "confidence": 0.85,
                "reason": "Buen momento para actividades de estudio"
            },
            {
                "date": "2025-12-12T10:00:00",
                "end_time": "2025-12-12T11:30:00",
                "confidence": 0.80,
                "reason": "Patrón consistente de estudio matutino"
            }
        ]
    }
    """
    global ml_models
    
    if not ml_models or not ml_models.models_trained:
        return jsonify({
            'success': False,
            'error': 'El modelo no está entrenado. Llama primero a /train'
        }), 400
    
    try:
        data = request.json
        title = data.get('title', '')
        duration_minutes = data.get('duration_minutes', 60)
        preferred_days = data.get('preferred_days', [0, 1, 2, 3, 4])  # Lunes a Viernes por defecto
        constraints = data.get('constraints', {})
        earliest_hour = constraints.get('earliest_hour', 8)
        latest_hour = constraints.get('latest_hour', 22)
        
        # Detectar tipo de evento del título
        title_lower = title.lower()
        is_study = any(word in title_lower for word in ['estudiar', 'estudio', 'examen', 'tarea', 'matemáticas', 'física', 'programación'])
        is_work = any(word in title_lower for word in ['trabajo', 'reunión', 'meeting', 'proyecto'])
        is_exercise = any(word in title_lower for word in ['ejercicio', 'gym', 'correr', 'deporte'])
        
        # Generar sugerencias basadas en ML
        suggestions = []
        now = datetime.now()
        
        # Evaluar próximos 7 días
        for day_offset in range(7):
            future_date = now + timedelta(days=day_offset)
            if future_date.weekday() not in preferred_days:
                continue
            
            # Evaluar diferentes horas del día
            for hour in range(earliest_hour, latest_hour - int(duration_minutes / 60)):
                productivity = ml_models.predict_productivity(
                    hour=hour,
                    day_of_week=future_date.weekday(),
                    duration=duration_minutes,
                    is_study=is_study,
                    is_work=is_work,
                    is_exercise=is_exercise
                )
                
                if productivity > 0.6:  # Solo sugerencias con alta productividad
                    start_dt = future_date.replace(hour=hour, minute=0, second=0, microsecond=0)
                    end_dt = start_dt + timedelta(minutes=duration_minutes)
                    
                    # Razones basadas en el contexto
                    reasons = []
                    if productivity > 0.85:
                        reasons.append("Momento óptimo de alta productividad")
                    elif productivity > 0.75:
                        reasons.append("Buena productividad esperada")
                    else:
                        reasons.append("Productividad moderada")
                    
                    if is_study and 9 <= hour <= 11:
                        reasons.append("Horario ideal para estudio")
                    elif is_exercise and (hour < 9 or hour >= 17):
                        reasons.append("Momento apropiado para ejercicio")
                    elif is_work and 9 <= hour <= 17:
                        reasons.append("Horario laboral productivo")
                    
                    suggestions.append({
                        'date': start_dt.isoformat(),
                        'end_time': end_dt.isoformat(),
                        'confidence': round(productivity, 2),
                        'reason': ' - '.join(reasons),
                        'day_name': ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][future_date.weekday()]
                    })
        
        # Ordenar por confianza y retornar top 3
        suggestions.sort(key=lambda x: x['confidence'], reverse=True)
        top_suggestions = suggestions[:3]
        
        if not top_suggestions:
            return jsonify({
                'success': False,
                'error': 'No se encontraron horarios óptimos con las restricciones dadas'
            }), 404
        
        return jsonify({
            'success': True,
            'suggestions': top_suggestions
        })
        
    except Exception as e:
        print(f"❌ Error generando predicciones: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/analyze-conflicts', methods=['POST'])
def analyze_conflicts():
    """
    Analiza conflictos potenciales para un horario propuesto
    
    Body:
    {
        "date": "2025-12-11T10:00:00",
        "end_time": "2025-12-11T11:30:00",
        "title": "Estudiar Física"
    }
    
    Respuesta:
    {
        "has_conflict": false,
        "conflict_score": 0.1,
        "warnings": [],
        "recommendations": ["Buen momento para estudiar"]
    }
    """
    global ml_models
    
    if not ml_models or not ml_models.models_trained:
        return jsonify({
            'success': False,
            'error': 'El modelo no está entrenado'
        }), 400
    
    try:
        data = request.json
        start_str = data.get('date', '')
        end_str = data.get('end_time', '')
        title = data.get('title', '')
        
        start_time = datetime.fromisoformat(start_str.replace('Z', '+00:00'))
        end_time = datetime.fromisoformat(end_str.replace('Z', '+00:00'))
        duration = (end_time - start_time).total_seconds() / 60
        
        # Detectar tipo de evento
        title_lower = title.lower()
        is_study = any(word in title_lower for word in ['estudiar', 'estudio', 'examen', 'tarea'])
        is_work = any(word in title_lower for word in ['trabajo', 'reunión', 'meeting'])
        is_exercise = any(word in title_lower for word in ['ejercicio', 'gym', 'correr'])
        
        # Predecir productividad para ese horario
        productivity = ml_models.predict_productivity(
            hour=start_time.hour,
            day_of_week=start_time.weekday(),
            duration=int(duration),
            is_study=is_study,
            is_work=is_work,
            is_exercise=is_exercise
        )
        
        # Generar análisis
        has_conflict = productivity < 0.4
        warnings = []
        recommendations = []
        
        if productivity < 0.4:
            warnings.append("Baja productividad esperada para este horario")
        elif productivity > 0.7:
            recommendations.append("Excelente momento para esta actividad")
        
        if start_time.hour < 7:
            warnings.append("Muy temprano, podría afectar el descanso")
        elif start_time.hour >= 22:
            warnings.append("Muy tarde, podría afectar el sueño")
        
        if is_study and start_time.hour > 20:
            warnings.append("No es el mejor momento para estudiar según tus patrones")
        elif is_exercise and 12 <= start_time.hour <= 14:
            warnings.append("Ejercicio durante horario de almuerzo podría no ser ideal")
        
        return jsonify({
            'success': True,
            'has_conflict': has_conflict,
            'conflict_score': round(1.0 - productivity, 2),
            'productivity_score': round(productivity, 2),
            'warnings': warnings,
            'recommendations': recommendations
        })
        
    except Exception as e:
        print(f"❌ Error analizando conflictos: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    print("=" * 60)
    print("🤖 ML MICROSERVICE - PREDICTOR DE CALENDARIO")
    print("=" * 60)
    print("📍 Puerto: 5000")
    print("📚 Endpoints:")
    print("   - GET  /health              - Health check")
    print("   - POST /train               - Entrenar modelo con temp_events.json")
    print("   - POST /predict             - Obtener 3 sugerencias de horarios")
    print("   - POST /analyze-conflicts   - Analizar conflictos")
    print("=" * 60)
    print()
    
    # Auto-entrenar al iniciar si hay datos disponibles
    events = load_training_data()
    if events:
        print(f"🎯 Auto-entrenando con {len(events)} eventos históricos...")
        ml_models = MLModels()
        try:
            ml_models.train_models(events)
            insights = ml_models.get_schedule_insights(events)
            print(f"✅ Modelos entrenados y listos para predicciones")
            print(f"📊 Productividad promedio: {insights.get('avg_productivity', 'N/A')}")
            print(f"⏰ Mejor hora: {insights.get('best_hour', 'N/A')}:00")
        except Exception as e:
            print(f"⚠️  Error en auto-entrenamiento: {e}")
    else:
        print("⚠️  No hay datos de entrenamiento. Usa POST /train después de cargar eventos")
    
    print()
    print("🚀 Iniciando servidor...")
    app.run(host='0.0.0.0', port=5000, debug=True)
