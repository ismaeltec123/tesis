"""
Microservicio de Machine Learning para Predicción de Reagendamiento
Usa Prophet (Facebook) para aprender patrones de usuarios
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import traceback

from services.prophet_trainer import ProphetTrainer
from services.prophet_predictor import ProphetPredictor
from services.model_manager import ModelManager
from utils.data_validator import DataValidator

app = Flask(__name__)
CORS(app)

# Inicializar servicios
trainer = ProphetTrainer()
predictor = ProphetPredictor()
model_manager = ModelManager()
validator = DataValidator()

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'ML Rescheduling Service',
        'prophet_version': '1.1.5',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/train', methods=['POST'])
def train_user_model():
    """
    Entrena modelo Prophet para un usuario
    
    Body:
    {
        "user_id": "user123",
        "events_history": [
            {
                "id": "evt_1",
                "date": "2025-11-15T10:00:00Z",
                "status": "finalizado",
                "type": "estudio",
                "title": "Estudiar Cálculo",
                "reschedule_reason": "no_tuve_tiempo"
            }
        ]
    }
    """
    try:
        data = request.json
        
        # Validar request
        is_valid, error_msg = validator.validate_training_request(data)
        if not is_valid:
            return jsonify({
                'status': 'error',
                'message': error_msg
            }), 400
        
        user_id = data['user_id']
        events_history = data['events_history']
        
        print(f"\n📊 Training request for user: {user_id}")
        print(f"   Events provided: {len(events_history)}")
        
        # Verificar si hay suficientes datos
        has_enough, validation_result = validator.check_sufficient_data(events_history)
        
        if not has_enough:
            print(f"❌ Insufficient data for user {user_id}")
            return jsonify({
                'status': 'insufficient_data',
                'user_id': user_id,
                'events_provided': validation_result['events_count'],
                'minimum_required': validation_result['minimum_required_events'],
                'weeks_of_data': validation_result['weeks_of_data'],
                'minimum_required_weeks': validation_result['minimum_required_weeks'],
                'days_until_ready': validation_result['days_until_ready'],
                'can_predict': False,
                'message': validation_result['message']
            }), 200
        
        # Entrenar modelo con Prophet
        print(f"✅ Sufficient data, training Prophet model...")
        training_result = trainer.train_model(user_id, events_history)
        
        if not training_result['success']:
            print(f"❌ Training failed: {training_result.get('error')}")
            return jsonify({
                'status': 'training_failed',
                'user_id': user_id,
                'error': training_result.get('error'),
                'can_predict': False
            }), 500
        
        # Guardar modelo
        model = training_result['model']
        model_saved = model_manager.save_model(user_id, model, training_result['metadata'])
        
        print(f"✅ Model trained and saved successfully")
        
        return jsonify({
            'status': 'trained',
            'user_id': user_id,
            'events_used': training_result['events_used'],
            'weeks_of_data': round(validation_result['weeks_of_data'], 2),
            'training_time_seconds': round(training_result['training_time_seconds'], 2),
            'model_saved': model_saved,
            'model_path': f"models/user_{user_id}.pkl",
            'can_predict': True,
            'prophet_components': training_result['prophet_components'],
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        print(f"❌ Error in /train: {e}")
        traceback.print_exc()
        return jsonify({
            'status': 'error',
            'message': str(e),
            'details': traceback.format_exc()
        }), 500

@app.route('/predict', methods=['POST'])
def predict_reschedule():
    """
    Genera predicciones de reagendamiento usando Prophet
    
    Body:
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
    """
    try:
        data = request.json
        
        # Validar request
        is_valid, error_msg = validator.validate_prediction_request(data)
        if not is_valid:
            return jsonify({
                'status': 'error',
                'message': error_msg
            }), 400
        
        user_id = data['user_id']
        incomplete_event = data['incomplete_event']
        events_history = data.get('events_history', [])
        future_calendar = data.get('future_calendar', [])
        
        print(f"\n🔮 Prediction request for user: {user_id}")
        
        # Verificar si existe modelo
        if not model_manager.model_exists(user_id):
            print(f"❌ Model not found for user {user_id}")
            return jsonify({
                'status': 'model_not_found',
                'user_id': user_id,
                'message': 'Modelo no entrenado. Ejecutar /train primero',
                'can_predict': False
            }), 404
        
        # Cargar modelo
        model, metadata = model_manager.load_model(user_id)
        
        if model is None:
            print(f"❌ Failed to load model for user {user_id}")
            return jsonify({
                'status': 'model_load_failed',
                'user_id': user_id,
                'message': 'Error al cargar modelo',
                'can_predict': False
            }), 500
        
        print(f"✅ Model loaded, generating predictions...")
        
        # Generar predicciones con Prophet
        prediction_result = predictor.predict_reschedule(
            user_id=user_id,
            model=model,
            incomplete_event=incomplete_event,
            events_history=events_history,
            future_calendar=future_calendar,
            model_metadata=metadata
        )
        
        if not prediction_result['success']:
            print(f"❌ Prediction failed: {prediction_result.get('error')}")
            return jsonify({
                'status': 'prediction_failed',
                'user_id': user_id,
                'error': prediction_result.get('error'),
                'can_predict': False
            }), 500
        
        print(f"✅ Generated {len(prediction_result['recommendations'])} recommendations")
        
        return jsonify({
            'status': 'success',
            'user_id': user_id,
            'ml_method': 'Prophet',
            'model_version': metadata.get('trained_at', 'unknown'),
            'confidence': prediction_result['confidence'],
            'recommendations': prediction_result['recommendations'],
            'metrics': prediction_result['metrics'],
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        print(f"❌ Error in /predict: {e}")
        traceback.print_exc()
        return jsonify({
            'status': 'error',
            'message': str(e),
            'details': traceback.format_exc()
        }), 500

@app.route('/status/<user_id>', methods=['GET'])
def get_user_status(user_id):
    """
    Verifica el estado del modelo de un usuario
    """
    try:
        model_exists = model_manager.model_exists(user_id)
        
        if not model_exists:
            return jsonify({
                'user_id': user_id,
                'model_exists': False,
                'can_predict': False,
                'ml_readiness': 'not_ready',
                'message': 'Modelo no encontrado'
            })
        
        metadata = model_manager.get_metadata(user_id)
        
        # Determinar estado de preparación
        events_count = metadata.get('events_count', 0)
        weeks_of_data = metadata.get('weeks_of_data', 0)
        
        if weeks_of_data < 2 or events_count < 20:
            ml_readiness = 'not_ready'
        elif weeks_of_data < 4 or events_count < 50:
            ml_readiness = 'learning'
        else:
            ml_readiness = 'ready'
        
        return jsonify({
            'user_id': user_id,
            'model_exists': True,
            'can_predict': True,
            'last_training': metadata.get('trained_at'),
            'events_in_model': events_count,
            'weeks_of_data': round(weeks_of_data, 2),
            'ml_readiness': ml_readiness,
            'prophet_components': metadata.get('prophet_components', {})
        })
        
    except Exception as e:
        print(f"❌ Error in /status: {e}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/models', methods=['GET'])
def list_models():
    """
    Lista todos los modelos entrenados
    """
    try:
        models = model_manager.list_all_models()
        return jsonify({
            'total_models': len(models),
            'models': models
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

if __name__ == '__main__':
    print("=" * 60)
    print("🤖 ML RESCHEDULING SERVICE STARTING...")
    print("=" * 60)
    print("📊 Using: Facebook Prophet ML Model")
    print("🚀 Server running on http://localhost:5000")
    print("=" * 60)
    print()
    
    app.run(host='0.0.0.0', port=5000, debug=True)
