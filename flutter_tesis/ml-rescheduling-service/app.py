"""
Microservicio de ML para Reagendamiento Inteligente de Eventos
Usa Prophet (Facebook) + Heurísticas Estadísticas
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime, timedelta
import sys
import os

# Importar servicios
from services.simple_recommender import SimpleMLRecommender
from services.prophet_recommender import ProphetMLRecommender

app = Flask(__name__)
CORS(app)

# Inicializar recomendadores
simple_recommender = SimpleMLRecommender()
prophet_recommender = ProphetMLRecommender()

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'ML Rescheduling Service',
        'version': '1.0.0',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/reschedule', methods=['POST'])
def reschedule_event():
    """
    Endpoint principal para recomendar reagendamiento de eventos
    
    Body:
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
                "type": "estudio",
                ...
            }
        ],
        "future_calendar": [
            {
                "date": "2025-12-10T09:00:00Z",
                "is_free": true
            }
        ]
    }
    """
    try:
        data = request.json
        
        # Validar datos
        if not data or 'event' not in data or 'user_history' not in data:
            return jsonify({
                'error': 'Missing required fields: event, user_history'
            }), 400
        
        event = data['event']
        user_history = data.get('user_history', [])
        future_calendar = data.get('future_calendar', [])
        user_id = data.get('user_id', 'anonymous')
        
        # Elegir método basado en cantidad de datos
        if len(user_history) < 15:
            # Pocos datos: usar heurísticas simples
            recommendations = simple_recommender.recommend_reschedule(
                event, 
                user_history, 
                future_calendar
            )
            ml_method = "Statistical Heuristics ML"
            confidence = "medium"
        else:
            # Suficientes datos: usar Prophet
            try:
                recommendations = prophet_recommender.recommend_reschedule(
                    event, 
                    user_history, 
                    future_calendar
                )
                ml_method = "Facebook Prophet ML Model"
                confidence = "high"
            except Exception as prophet_error:
                print(f"Prophet error: {prophet_error}, fallback to heuristics")
                # Fallback a heurísticas si Prophet falla
                recommendations = simple_recommender.recommend_reschedule(
                    event, 
                    user_history, 
                    future_calendar
                )
                ml_method = "Statistical Heuristics ML (Prophet fallback)"
                confidence = "medium"
        
        return jsonify({
            'user_id': user_id,
            'original_event': event,
            'recommendations': recommendations,
            'ml_method': ml_method,
            'confidence': confidence,
            'data_points_used': len(user_history),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        print(f"Error in /reschedule: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'error': str(e),
            'details': 'Internal server error'
        }), 500

@app.route('/analyze', methods=['POST'])
def analyze_patterns():
    """
    Endpoint para analizar patrones del usuario
    
    Body:
    {
        "user_id": "user123",
        "user_history": [...]
    }
    """
    try:
        data = request.json
        user_history = data.get('user_history', [])
        
        if len(user_history) < 5:
            return jsonify({
                'error': 'Insufficient data for analysis',
                'minimum_required': 5,
                'received': len(user_history)
            }), 400
        
        # Analizar patrones
        patterns = simple_recommender._analyze_patterns(user_history)
        
        # Agregar insights
        best_hours = sorted(patterns['by_hour'].items(), key=lambda x: x[1], reverse=True)[:3]
        best_days = sorted(patterns['by_day'].items(), key=lambda x: x[1], reverse=True)[:3]
        
        day_names = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']
        
        return jsonify({
            'patterns': patterns,
            'insights': {
                'best_hours': [
                    {'hour': h, 'completion_rate': rate, 'time': f"{h}:00"} 
                    for h, rate in best_hours
                ],
                'best_days': [
                    {'day': d, 'completion_rate': rate, 'name': day_names[d]} 
                    for d, rate in best_days
                ],
                'overall_completion_rate': patterns['total_completed'] / patterns['total_events'] if patterns['total_events'] > 0 else 0
            },
            'data_points': len(user_history)
        })
        
    except Exception as e:
        print(f"Error in /analyze: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("🤖 ML Rescheduling Service Starting...")
    print("📊 Using: Prophet + Statistical Heuristics")
    print("🚀 Server running on http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)
